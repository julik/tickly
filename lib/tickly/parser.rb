require 'strscan'

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
      # Use multiple_expressions = true so that the top-level
      # parsed script is always an array of expressions
      sub_parse(bare_io, stop_char = nil, stack_depth = 0, multiple_expressions = true)
    end
    
    # Override this to remove any unneeded subexpressions.
    # Return the modified expression. If you return nil, the result
    # will not be added to the expression list
    def compact_subexpr(expr, at_depth)
      expr
    end
    
    private
    
    LAST_CHAR = -1..-1 # If we were 1.9 only we could use -1
    ESC = 92.chr # Backslash (\)
    QUOTES = %w( ' " )
    
    # Package the expressions, stack and buffer.
    # We use a special flag to tell us whether we need multuple expressions
    # or not, if not we just discard them
    def wrap_up(expressions, stack, stack_depth, multiple_expressions)
      return stack unless multiple_expressions
      
      expressions << stack if stack.any?
      
      return expressions
    end
    
    def tokens_to_stack(chunk, stack, chop_chars = 1)
      range = 0..(-1 - chop_chars)
      chunk[range].split(/\s+/).each do | bareword |
        stack << bareword unless bareword.empty?
      end
    end
    
    # Parse from a passed IO object either until an unescaped stop_char is reached
    # or until the IO is exhausted. The last argument is the class used to
    # compose the subexpression being parsed. The subparser is reentrant and not
    # destructive for the object containing it.
    def sub_parse(io, stop_char = nil, stack_depth = 0, multiple_expressions = false)
      # A standard stack is an expression that does not evaluate to a string
      expressions = []
      stack = []
      
      magic_chars  = [stop_char].compact + %w( { [ ' " )
      regexp_class_subexpression_openers = '[%s]' % magic_chars.map{|c| Regexp.escape(c) }.join
      
      # Match any character that can open a subexpression, or where this parser has to return
      re = /#{regexp_class_subexpression_openers}/
      
      loop do
        line_start_pos = io.pos
        line = io.gets
        
        # When the IO eof?s return the expressions
        return wrap_up(expressions, stack, stack_depth, multiple_expressions) if line.nil?
        
        line.chomp!
        
        scanner = StringScanner.new(line)
        until scanner.eos?
          
          chunk_with_terminator = scanner.scan_until(re)
          if chunk_with_terminator
            # Memorize the position within line
            restart_scanning_at = line_start_pos + scanner.pos
            
            # Grab everything until the latest character and put it onto the stack
            tokens_to_stack(chunk_with_terminator, stack)
            
            # char is the magic "special" character at the end of the matched string
            char = chunk_with_terminator[LAST_CHAR]
            
            if char == stop_char # Bail out of a subexpr
              puts "Bailing out of a subexpr at depth #{stack_depth}"
              return wrap_up(expressions, stack, stack_depth, multiple_expressions)
            elsif char == '[' # Opens a new string expression
              # Rewind the IO to the place where our special expression ended
              io.seek(restart_scanning_at) 
              scanner.terminate
              stack << [:b] + sub_parse(io, ']', stack_depth + 1)
            elsif char == '{' # Opens a new literal expression  
              # Rewind the IO to the place where our special expression ended
              io.seek(restart_scanning_at)
              scanner.terminate
              stack << [:c] + sub_parse(io, '}', stack_depth + 1)
            elsif QUOTES.include?(char)
              # Rewind the IO to the place where our special expression ended
              io.seek(restart_scanning_at)
              scanner.terminate
              stack << parse_str(io, char)
            end
          else # Nothing to do on this str
            # Scan until the end of str, the scanner will arrive to eos
            chunk_until_eos = scanner.scan_until(/$/)
            expressions << stack if stack.any?
            tokens_to_stack(chunk_until_eos, stack, stack_depth)
          end
        end
      end
      
      return wrap_up(expressions, stack, stack_depth, multiple_expressions)
    end
    
    def chomp!(stack)
      stack.delete_at(-1) if stack.any? && stack[-1].nil?
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
    
  end
end