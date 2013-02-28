require 'stringio'

module Tickly

  # Represents an expression between curly braces (within which no text substitution will be done)
  # like  { 1 2 3 }
  class LiteralExpr < Array
  end

  # Represents an expression between square brackets (where text substitution will be done)
  # like  [1 2 3]
  class StringExpr < Array
  end

  class Parser
  
    ESC = 92.chr # Backslash (\)
  
    def parse(io_or_str, stop_char = nil)
      io = io_or_str.respond_to?(:readchar) ? io : StringIO.new(io_or_str)
    
      # A standard stack is an expression that does not evaluate to a string
      stack = LiteralExpr.new
      buf = ''
      until io.eof?
        char = io.readchar
      
        if buf[-1] != ESC
          if char == stop_char
            stack << buf if (buf.length > 0)
            return deflatten(stack)
          elsif char == " " || char == "\n" # Space
            if buf.length > 0
              stack << buf
              buf = ''
            end
            if char == "\n" # Introduce a stack separator!
              stack << nil
            end
          elsif char == '[' # Opens a new string expression
            stack << buf if (buf.length > 0)
            inner_expr = parse(io, ']')
            stack.push(LiteralExpr.new(inner_expr))
          elsif char == '{' # Opens a new literal expression  
            stack << buf if (buf.length > 0)
            inner_expr = parse(io, '}')
            stack.push(LiteralExpr.new(inner_expr))
          elsif char == '"'
            stack << buf if (buf.length > 0)
            str = parse(io, '"')
            stack.push(str.join(' '))
          elsif char == "'"
            stack << buf if (buf.length > 0)
            str = parse(io, "'")
            stack.push(str.join(' '))
          else
            buf << char
          end
        else
          buf << char
        end
      end
    
      # Ramass any remaining buffer contents
      stack << buf if (buf.length > 0)
    
      # Eliminate line breaks which signify expression separators
      #    deflatten(stack)
      # Expand one-element expressions of the same kind
      expand(stack)
    end
  
    def expand(stack)
      stack.map do | element |
        if element.is_a?(Array) && element.length == 1 && element[0].class == element.class
          element[0]
        else
          element
        end
      end
    end
  
    def deflatten(stack)
      new_stack = []
      new_stack << []
      stack.each do | elem |
        if elem.nil?
          new_stack << []
        else
          new_stack[-1] << elem
        end
      end
      new_stack.reject{|e| e == []}
    end
  end
end