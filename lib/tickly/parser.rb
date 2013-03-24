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
      reader = Bychar.wrap(bare_io)
      # Use multiple_expressions = true so that the top-level parsed script is always an array
      # of expressions
      parse_expr(reader, stop_char = nil, stack_depth = 0, multiple_expressions = true)
    end
    
    # Override this to remove any unneeded subexpressions.
    # Return the modified expression. If you return nil, the result
    # will not be added to the expression list. You can also use this
    # method for bottom-up expression evaluation, returning the result
    # of the expression being evaluated. This method will be first called
    # for the innermost expressions and then proceed up the call stack.
    def compact_subexpr(expr, at_depth)
      expr
    end
    
    private
    
    LAST_CHAR = -1..-1 # If we were 1.9 only we could use -1
    TERMINATORS = ["\n", ";"]
    ESC = 92.chr # Backslash (\)
    
    # Package the expressions, stack and buffer.
    # We use a special flag to tell us whether we need multuple expressions.
    # If we do, the expressions will be returned. If not, just the stack.
    # Also, anything that remains on the stack will be put on the expressions
    # list if multiple_expressions is true.
    def wrap_up(expressions, stack, buf, stack_depth, multiple_expressions)
      stack << buf if (buf.length > 0)
      return stack unless multiple_expressions
      
      expressions << stack if stack.any?
      
      return expressions
    end
    
    # If the passed buf contains any bytes, put them on the stack and
    # empty the buffer
    def consume_remaining_buffer(stack, buf)
      return if buf.length == 0
      stack << buf.dup
      buf.replace('')
    end
    
    # Parse from a passed IO object either until an unescaped stop_char is reached
    # or until the IO is exhausted. The last argument is the class used to
    # compose the subexpression being parsed. The subparser is reentrant and not
    # destructive for the object containing it.
    def parse_expr(io, stop_char = nil, stack_depth = 0, multiple_expressions = false)
      # A standard stack is an expression that does not evaluate to a string
      expressions = []
      stack = []
      buf = ''
      
      no_eof do
        char = io.read_one_char!
        
        if char == stop_char # Bail out of a subexpr
          # TODO: default stop_char is nil, and this is also what gets returned from a depleted
          # IO on IO#read(). We should do that in Bychar.
          # Handle any remaining subexpressions
          return wrap_up(expressions, stack, buf, stack_depth, multiple_expressions)
        elsif char == " " || char == "\n" # Space
          if buf.length > 0
            stack << buf
            buf = ''
          end
          if TERMINATORS.include?(char) && stack.any? # Introduce a stack separator! This is a new line
            
            # First get rid of the remaining buffer data
            consume_remaining_buffer(stack, buf)
            
            # Since we now finished an expression and it is on the stack,
            # we can run this expression through the filter
            filtered_expr = compact_subexpr(stack, stack_depth + 1)
            
            # Only preserve the parsed expression if it's not nil
            expressions << filtered_expr unless filtered_expr.nil?
            
            # Reset the stack for the next expression
            stack = []
            
            # Note that we will return multiple expressions instead of one
            multiple_expressions = true
          end
        elsif char == '[' # Opens a new string expression
          consume_remaining_buffer(stack, buf)
          stack << [:b] + parse_expr(io, ']', stack_depth + 1)
        elsif char == '{' # Opens a new literal expression  
          consume_remaining_buffer(stack, buf)
          stack << [:c] + parse_expr(io, '}', stack_depth + 1)
        elsif char == '"'
          consume_remaining_buffer(stack, buf)
          stack << parse_str(io, '"')
        elsif char == "'"
          consume_remaining_buffer(stack, buf)
          stack << parse_str(io, "'")
        else
          buf << char
        end
      end
      
      return wrap_up(expressions, stack, buf, stack_depth, multiple_expressions)
    end
    
    def no_eof(&blk)
      begin
        loop(&blk)
      rescue Bychar::EOF
      end
    end
    
    def parse_str(io, stop_char)
      buf = ''
      no_eof do
        c = io.read_one_char!
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