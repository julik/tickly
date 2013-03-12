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
    def sub_parse(io, stop_char = nil, expr_class = LiteralExpr, stack_depth = 0)
      # A standard stack is an expression that does not evaluate to a string
      stack = expr_class.new
      buf = ''
      last_char_was_linebreak = false
      until io.eof?
        char = io.read(1)
        
        if buf[LAST_CHAR] != ESC
          if char == stop_char # Bail out of a subexpr
            stack << buf if (buf.length > 0)
            return cleanup(stack, stack_depth)
          elsif char == " " || char == "\n" # Space
            if buf.length > 0
              stack << buf
              buf = ''
            end
            if char == "\n" # Introduce a stack separator! This is a new line
              unless last_char_was_linebreak
                last_char_was_linebreak = true
                
                # Take some action. We need to wrap the last
                if stack.any?
                  #puts "Sutuation at last linebreak: #{stack.inspect} @ #{stack_depth}"
                  stack << nil
                end
              end
            end
          elsif char == '[' # Opens a new string expression
            stack << buf if (buf.length > 0)
            last_char_was_linebreak = false
            stack << sub_parse(io, ']', StringExpr, stack_depth + 1)
          elsif char == '{' # Opens a new literal expression  
            stack << buf if (buf.length > 0)
            last_char_was_linebreak = false
            stack << sub_parse(io, '}', LiteralExpr, stack_depth + 1)
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
    
      cleanup(stack, stack_depth)
    end
    
    private
    
    ESC = 92.chr # Backslash (\)
    
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
      [StringExpr, LiteralExpr].include?(something.class)
    end
    
    # Cleans up a subexpression stack. Currently it only removes nil objects
    # in-between items (which act as line separators)
    def cleanup(expr, stack_depth)
      Tickly.split_array(expr)
    end
    
    def expr_is_node?(expr, stack_depth)
      stack_depth == 0 && expr[0].is_a?(String) && expr[1].is_a?(LiteralExpr)
    end
    
    def trim(expr, stack_depth)
      return expr unless expr_is_node?(expr, stack_depth)
      
    end
    
  end
end