require 'stringio'
require 'bychar'

module Tickly
  # Simplistic, incomplete and most likely incorrect TCL parser
  class Parser
    
    # Parses a piece of TCL and returns it converted into internal expression
    # structures. A basic TCL expression is just an array of Strings. An expression
    # in curly braces will have the symbol :c tacked onto the beginning of the array.
    # An expression in square braces will have the symbol :b tacked onto the beginning.
    # This method always returns a Array of expressions. If you only fed it one expression,
    # this expression will be the only element of the array.
    # The correct way to use the returned results is thusly:
    #
    #   p = Tickly::Parser.new
    #   expressions = p.parse("2 + 2") #=> [["2", "+", "2"]]
    #   expression = expressions[0] #=> ["2", "2"]
    def parse(io_or_str)
      bare_io = io_or_str.respond_to?(:read) ? io_or_str : StringIO.new(io_or_str)
      # Wrap the IO in a Bychar buffer to read faster
      reader = Bychar::Reader.new(bare_io)
      # Use multiple_expressions = true so that the top-level parsed script is always an array
      # of expressions
      sub_parse(reader, stop_char = nil, stack_depth = 0, multiple_expressions = true)
    end
    
    # Override this to remove any unneeded subexpressions.
    # Return the modified expression. If you return nil, the result
    # will not be added to the expression list
    def compact_subexpr(expr, at_depth)
      expr
    end
    
    private
    
    LAST_CHAR = -1..-1 # If we were 1.9 only we could use -1
    TERMINATORS = ["\n", ";"]
    ESC = 92.chr # Backslash (\)
    
    # Package the expressions, stack and buffer.
    # We use a special flag to tell us whether we need multuple expressions
    # or not, if not we just discard them
    def wrap_up(expressions, stack, buf, stack_depth, multiple_expressions)
      stack << buf if (buf.length > 0)
      return stack unless multiple_expressions
      
      expressions << stack if stack.any?
      
      return expressions
    end
    
    # Parse from a passed IO object either until an unescaped stop_char is reached
    # or until the IO is exhausted. The last argument is the class used to
    # compose the subexpression being parsed. The subparser is reentrant and not
    # destructive for the object containing it.
    def sub_parse(io, stop_char = nil, stack_depth = 0, multiple_expressions = false)
      # A standard stack is an expression that does not evaluate to a string
      expressions = []
      stack = []
      buf = ''
      last_char_was_linebreak = false
      
      no_eof do
        char = io.read_one_byte!
        
        if char == stop_char # Bail out of a subexpr
          # Handle any remaining subexpressions
          return wrap_up(expressions, stack, buf, stack_depth, multiple_expressions)
        elsif char == " " || char == "\n" # Space
          if buf.length > 0
            stack << buf
            buf = ''
          end
          if TERMINATORS.include?(char) && stack.any? && !last_char_was_linebreak # Introduce a stack separator! This is a new line
            stack << buf if buf.length > 0
            # Immediately run this expression through the filter
            filtered_expr = compact_subexpr(stack, stack_depth + 1)
            stack = []
            
            # Only preserve the parsed expression if it's not nil
            expressions << filtered_expr unless filtered_expr.nil?
            
            last_char_was_linebreak = true
            multiple_expressions = true
            #puts "Next expression! #{expressions.inspect} #{stack.inspect} #{buf.inspect}"
          else
            last_char_was_linebreak = false
          end
        elsif char == '[' # Opens a new string expression
          stack << buf if (buf.length > 0)
          stack << [:b] + sub_parse(io, ']', stack_depth + 1)
        elsif char == '{' # Opens a new literal expression  
          stack << buf if (buf.length > 0)
          stack << [:c] + sub_parse(io, '}', stack_depth + 1)
        elsif char == '"'
          stack << buf if (buf.length > 0)
          stack << parse_str(io, '"')
        elsif char == "'"
          stack << buf if (buf.length > 0)
          stack << parse_str(io, "'")
        else
          buf << char
        end
      end
      
      return wrap_up(expressions, stack, buf, stack_depth, multiple_expressions)
    end
    
    def chomp!(stack)
      stack.delete_at(-1) if stack.any? && stack[-1].nil?
    end
    
    def no_eof(&blk)
      begin
        loop(&blk)
      rescue Bychar::EOFError
      end
    end
    
    def parse_str(io, stop_char)
      buf = ''
      no_eof do
        c = io.read_one_byte!
        if c == stop_char && buf[LAST_CHAR] != ESC
          return buf
        elsif buf[LAST_CHAR] == ESC # Eat out the escape char
          buf = buf[0..-2] # Trim the escape character at the end of the buffer
          buf << c
        else
          buf << c
        end
      end
      
      return buf
    end
    
  end
end