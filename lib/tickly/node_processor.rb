module Tickly
  # A combination of a Parser and an Evaluator
  # Evaluates a passed Nuke script without expanding it's inner arguments.
  # The TCL should look like Nuke's node commands:
  #
  #   NodeClass { 
  #     foo bar
  #     baz bad
  #   }
  #
  # You have to add the Classes that you want to instantiate for nodes using add_node_handler_class
  # and every time the parser encounters that node the node will be instantiated
  # and the node options (actually TCL commands) will be passed to the constructor,
  # as a Ruby Hash with string keys. 
  # Every value of the knobs hash will be the AST as returned by the Parser.
  #
  #    class Blur
  #      def initialize(knobs_hash)
  #         puts knobs_hash.inspect
  #      end
  #    end
  #    
  #    e = Tickly::NodeProcessor.new
  #    e.add_node_handler_class Blur
  #    e.parse(File.open("/path/to/script.nk")) do | blur_node |
  #      # do whatever you want to the node instance
  #      end
  #    end
  class NodeProcessor
    def initialize
      @evaluator = Tickly::Evaluator.new
      @parser = Ratchet.new
      @parser.expr_callback = method(:filter_expression)
    end
    
    # Add a Class object that can instantiate node handlers. The last part of the class name
    # has to match the name of the Nuke node that you want to capture.
    # For example, to capture Tracker3 nodes a name like this will do:
    #     Whatever::YourModule::Better::Tracker3
    def add_node_handler_class(class_object)
      @evaluator.add_node_handler_class(class_object)
    end
    
    # Parses from the passed IO or string and yields every node
    # that has been instantiated
    def parse(io_or_str, &nuke_node_callback)
      raise "You need to pass a block" unless block_given?
      @node_handler = nuke_node_callback
      @parser.parse(io_or_str)
    end
    
    private
    
    class Ratchet < Parser #:nodoc: :all
      attr_accessor :expr_callback
      def expand_subexpr!(expr, at_depth)
        expr_callback.call(expr, at_depth)
      end
    end
    
    def filter_expression(expression, at_depth)
      # Leave all expressions which are deeper than 1
      # intact
      return if at_depth > 1
      
      # Skip all nodes which are not interesting for
      # the evaluator to do
      unless @evaluator.will_capture?(expression)
        expression.replace([]) # Empty it.
        return
      end
      
      # And immediately evaluate
      # TODO: also yield it!
      node_instance = @evaluator.evaluate(expression)
      @node_handler.call(node_instance)
    end
  end
end