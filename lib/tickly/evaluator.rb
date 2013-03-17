module Tickly
  # Evaluates a passed TCL expression without expanding it's inner arguments.
  # The TCL should look like Nuke's node commands:
  #
  #   NodeClass { 
  #     foo bar
  #     baz bad
  #   }
  #
  # You have to add the Classes that you want to instantiate for nodes using add_node_handler_class
  # and the evaluator will instantiate the classes it finds in the passed expression and pass the
  # node options (actually TCL commands) to the constructor, as a Ruby Hash with string keys. 
  # Every value of the knobs hash will be the AST as returned by the Parser.
  # You have to pass every expression returned by Tickly::Parser#parse separately.
  #
  #    class Blur
  #      def initialize(knobs_hash)
  #         puts knobs_hash.inspect
  #      end
  #    end
  #    
  #    e = Tickly::Evaluator.new
  #    e.add_node_handler_class Blur
  #    p = Tickly::Parser.new
  #     
  #    expressions = p.parse(some_nuke_script)
  #    expressions.each do | expr |
  #      # If expr is a Nuke node constructor, a new Blur will be created and yielded
  #      e.evaluate(expr) do | node_instance|
  #         # do whatever you want to the node instance
  #      end
  #    end
  class Evaluator
    def initialize
      @node_handlers = []
    end
    
    # Add a Class object that can instantiate node handlers. The last part of the class name
    # has to match the name of the Nuke node that you want to capture.
    # For example, to capture Tracker3 nodes a name like this will do:
    #     Whatever::YourModule::Better::Tracker3
    def add_node_handler_class(handler_class)
      @node_handlers << handler_class
    end
    
    # Evaluates a single Nuke TCL command, and if it is a node constructor
    # and a class with a corresponding name has been added using add_node_handler_class
    # the class will be instantiated and yielded to the block. The instance will also be returned
    # at the end of the method. This method evaluates one expression at a time
    # (it's more of a pattern matcher really)
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
        handler_instance = handler_class.new(hash_of_args)
        
        # Both return and yield it
        yield handler_instance if block_given?
        handler_instance
      end
    end
    
    private
    
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