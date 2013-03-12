module Tickly
  # Evaluates a passed TCL expression without expanding it's inner arguments.
  # The TCL should look like Nuke's node commands (i.e. NodeClass { foo bar; baz bad; } and so on)
  # You have to add the Classes that you want to instantiate for nodes using add_node_handler_class
  # and the evaluator will instantiate the classes it finds in the passed expression and pass the
  # node options (actually TCL commands) to the constructor, as a Ruby Hash with string keys.
  class Evaluator
    def initialize
      @node_handlers = []
    end
    
    def add_node_handler_class(handler_class)
      @node_handlers << handler_class
    end
    
    def evaluate(expr)
      if multiple_atoms?(expr) && has_subcommand?(expr) && has_handler?(expr) 
        handler_class = @node_handlers.find{|e| unconst_name(e) == expr[0]}
        handler_arguments = expr[1]
        hash_of_args = {}
        # Use 1..-1 to skip the curly brace symbol
        expr[1][1..-1].map do | e |
          # The name of the command is the first element, always
          hash_of_args[e[0]] = e[1]
        end
        
        # Instantiate the handler with the options
        handler_class.new(hash_of_args)
      end
    end
    
    def multiple_atoms?(expr)
      expr.length > 1
    end
    
    def has_handler?(expr)
      @node_handlers.map{|handler_class| unconst_name(handler_class) }.include?(expr[0])
    end
    
    def unconst_name(some_module)
      some_module.to_s.split('::').pop
    end
    
    def has_subcommand?(expr)
      expr[1][0] == :c
    end
  end
end