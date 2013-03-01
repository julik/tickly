module Tickly
  class Tokenizer
    def tokenize(stack)
      tokens = stack.class.new
      stack.each do | stack_elem |
        if stack_elem.is_a?(Array) && stack_elem[0].is_a?(String) # command
          tokens.push stack.class.new([:cmd, stack_elem.shift, tokenize(stack_elem)])
        elsif stack_elem.is_a?(Array) # subexpr
          tokens.push tokenize(stack_elem)
        elsif stack_elem.is_a?(String) # simplest
          tokens.push stack_elem
        end
      end
    
      tokens
    end
  end
end