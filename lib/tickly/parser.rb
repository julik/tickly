require 'stringio'

module Tickly
  
  class Parser

    # Parses a piece of TCL and returns it converted into internal expression
    # structures (nested StringExpr or LiteralExp objects).
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
    def sub_parse(io, stop_char = nil, expr_class = LiteralExpr)
      # A standard stack is an expression that does not evaluate to a string
      stack = expr_class.new
      buf = ''
      until io.eof?
        char = io.read(1)
        
        if buf[LAST_CHAR] != ESC
          if char == stop_char # Bail out of a subexpr
            stack << buf if (buf.length > 0)
            return cleanup(stack)
          elsif char == " " || char == "\n" # Space
            if buf.length > 0
              stack << buf
              buf = ''
            end
            if char == "\n" # Introduce a stack separator! This is a new line
              stack << nil
            end
          elsif char == '[' # Opens a new string expression
            stack << buf if (buf.length > 0)
            stack << sub_parse(io, ']', StringExpr)
          elsif char == '{' # Opens a new literal expression  
            stack << buf if (buf.length > 0)
            stack << sub_parse(io, '}', LiteralExpr)
          elsif char == '"'
            stack << buf if (buf.length > 0)
            stack << parse_str(io, '"')
          elsif char == "'"
            stack << buf if (buf.length > 0)
            stack << parse_str(io, "'")
          else
            buf << char
          end
        else
          buf << char
        end
      end
    
      # Ramass any remaining buffer contents
      stack << buf if (buf.length > 0)
    
      cleanup(stack)
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
    def cleanup(expr)
      # Ensure multiple consecutive line breaks are ignored
      no_multiple_breaks = Tickly.singularize_nils_in(expr)
      # Convert line breaks into subexpressions
      Tickly.split_array(no_multiple_breaks)
    end
  
  end
end