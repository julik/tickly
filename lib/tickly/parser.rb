require 'stringio'

module Tickly
  
  class Parser
    
    # If you set this to an array of node names that you want to preserve,
    # all the other nodes will be discarded during parsing. This helps to reduce
    # memory consumption during parsing
    # since you are likely to onyl be interested in specific node classes.
    #
    #  p.specific_nodes = %w( Tracker3 Tracker4 )
    #
    attr_accessor :specific_nodes
    
    # Parses a piece of TCL and returns it converted into internal expression
    # structures (nested StringExpr or LiteralExpr objects).
    def parse(io_or_str)
      io = io_or_str.respond_to?(:read) ? io_or_str : StringIO.new(io_or_str)
      sub_parse(io)
    end
    
    private
    
    LAST_CHAR = -1..-1 # If we were 1.9 only we could use -1
    
    # Parse from a passed IO object either until an unescaped stop_char is reached
    # or until the IO is exhausted. The last argument is the class used to
    # compose the subexpression being parsed. The subparser is reentrant and not
    # destructive for the object containing it.
    def sub_parse(io, stop_char = nil, stack_depth = 0)
      # A standard stack is an expression that does not evaluate to a string
      stack = []
      buf = ''
      last_char_was_linebreak = false
      until io.eof?
        char = io.read(1)
        
        if buf[LAST_CHAR] != ESC
          if char == stop_char # Bail out of a subexpr
            stack << buf if (buf.length > 0)
            # Chip away the tailing linebreak if it's there
            chomp!(stack)
            return cleanup(stack, stack_depth)
          elsif char == " " || char == "\n" # Space
            if buf.length > 0
              stack << buf
              buf = ''
            end
            if char == "\n" # Introduce a stack separator! This is a new line
              if stack.any? && !last_char_was_linebreak
                last_char_was_linebreak = true
                stack = handle_expr_terminator(stack, stack_depth)
              end
            end
          elsif char == '[' # Opens a new string expression
            stack << buf if (buf.length > 0)
            last_char_was_linebreak = false
            stack << [:b] + sub_parse(io, ']', stack_depth + 1)
          elsif char == '{' # Opens a new literal expression  
            stack << buf if (buf.length > 0)
            last_char_was_linebreak = false
            stack << [:c] + sub_parse(io, '}', stack_depth + 1)
          elsif char == '"'
            stack << buf if (buf.length > 0)
            last_char_was_linebreak = false
            stack << parse_str(io, '"')
          elsif char == "'"
            stack << buf if (buf.length > 0)
            last_char_was_linebreak = false
            stack << parse_str(io, "'")
          else
            last_char_was_linebreak = false
            buf << char
          end
        else
          last_char_was_linebreak = false
          buf << char
        end
      end
    
      # Ramass any remaining buffer contents
      stack << buf if (buf.length > 0)
      
      # Handle any remaining subexpressions
      if stack.include?(nil)
        stack = handle_expr_terminator(stack, stack_depth)
      end
      # Chip awiy the trailing null
      chomp!(stack)
      
      cleanup(stack, stack_depth)
    end
    
    # Override this to remove any unneeded subexpressions
    def expand_subexpr!(expr)
    end
    
    private
    
    ESC = 92.chr # Backslash (\)
    
    def chomp!(stack)
      stack.delete_at(-1) if stack.any? && stack[-1].nil?
    end
    
    def handle_expr_terminator(stack, stack_depth)
      # Figure out whether there was a previous expr terminator
      previous_i = stack.index(nil)
      # If there were none, just get this over with. Wrap the stack contents
      # into a subexpression and carry on.
      unless previous_i
        subexpr = stack
        expand_subexpr!(subexpr)
        return [subexpr] + [nil]
      end
      
      # Now, if there was one, we are the next subexpr in line that just terminated.
      # What we need to do is pick out all the elements from that terminator onwards
      # and wrap them.
      subexpr = stack[previous_i+1..-1]
      
      # Use expand_subexpr! to trim away any fat that we don't need
      expand_subexpr!(subexpr)
      
      return stack[0...previous_i] + [subexpr] + [nil]
    end
    
    def parse_str(io, stop_char)
      buf = ''
      until io.eof?
        c = io.read(1)
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
    
    # Tells whether a passed object is a StringExpr or LiteralExpr
    def expr?(something)
      something.is_a?(Array) && something[0].is_a?(Symbol)
    end
    
    # Cleans up a subexpression stack. Currently it only removes nil objects
    # in-between items (which act as line separators)
    def cleanup(expr, stack_depth)
      expr
    end
    
  end
end