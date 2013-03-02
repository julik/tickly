require 'stringio'

module Tickly
  
  class Parser

    # Parses a piece of TCL and returns it converted into internal expression
    # structures (nested StringExpr or LiteralExp objects).
    def parse(io_or_str)
      io = io_or_str.respond_to?(:readchar) ? io_or_str : StringIO.new(io_or_str)
      sub_parse(io)
    end
    
    private
    
    # Parse from a passed IO object either until an unescaped stop_char is reached
    # or until the IO is exhausted. The last argument is the class used to
    # compose the subexpression being parsed. The subparser is reentrant and not
    # destructive for the object containing it.
    def sub_parse(io, stop_char = nil, expr_class = LiteralExpr)
      # A standard stack is an expression that does not evaluate to a string
      stack = expr_class.new
      buf = ''
      until io.eof?
        char = io.readchar
        
        if buf[-1] != ESC
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
        c = io.readchar
        if c == stop_char && buf[-1] != ESC
          return buf
        elsif buf[-1] == ESC # Eat out the escape char
          buf = buf[0..-2] # Trim the escape character at the end of the buffer
          buf << c
        else
          buf << c
        end
      end
      
      return buf
    end
    
    def expand_one_elements!(expr)
      expr.map! do | element |
        if expr?(element) && element.length == 1 && element[0].class == element.class
          element[0]
        else
          element
        end
      end
    end
    
    def remove_empty_elements!(expr)
      expr.reject! {|e|  expr?(e) && e.empty? }
    end
    
    # Tells whether a passed object is a StringExpr or LiteralExpr
    def expr?(something)
      [StringExpr, LiteralExpr].include?(something.class)
    end
    
    # Cleans up a subexpression stack. Currently it only removes nil objects
    # in-between items (which act as line separators)
    def cleanup(expr)
      # Expand one-element expressions of the same class
      #expand_one_elements!(expr)
      
      # Remove empty subexprs
      #remove_empty_elements!(expr)
      
      # Squeeze out the leading and trailing nils
      expr.delete_at(0) while (expr.any? && expr[0].nil?)
      expr.delete_at(-1) while (expr.any? && expr[-1].nil?)
      
      # Convert line breaks into subexpressions
      Tickly.split_array(expr)
    end
  
  end
end