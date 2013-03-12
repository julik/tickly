module Tickly
  # A more refined version of the Parser class that can scope itself to the passed Nuke node
  # classnames. It will toss all of the node data that is not relevant, keeping only nodes that are
  # required.
  class NodeExtractor < Parser
    def initialize(*interesting_node_class_names)
      @nodes = interesting_node_class_names
    end
    
    # Override this to remove any unneeded subexpressions
    def expand_subexpr!(expr, at_depth)
      if is_node_constructor?(expr, at_depth)
        node_class_name = expr[0]
        expr.replace([:discarded]) unless @nodes.include?(node_class_name)
      end
    end
    
    def is_node_constructor?(expr, depth)
      depth == 1 && expr[0].is_a?(String) && expr.length == 2 && expr[1][0] == :c
    end
  end
end
