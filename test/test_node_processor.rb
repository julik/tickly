require 'helper'

class TestParserEvaluator < Test::Unit::TestCase
  include Tickly::Emitter
  
  HUGE_SCRIPT = File.open(File.dirname(__FILE__) + "/test-data/huge_nuke_tcl.tcl")
  NUKE7_SCRIPT = File.open(File.dirname(__FILE__) + "/test-data/nuke7_tracker_2tracks.nk")
  
  class Tracker4
    attr_reader :knobs
    def initialize(knobs)
      @knobs = knobs
    end
  end
  
  class NodeCaptured < RuntimeError; end
  
  def test_processes_nodes
    pe = Tickly::NodeProcessor.new
    pe.add_node_handler_class(Tracker4)
    
    assert_raise(NodeCaptured) do
      pe.parse(NUKE7_SCRIPT) do | node |
        
        assert_kind_of Tracker4, node
        assert_equal "Tracker1", node.knobs["name"]
        
        raise NodeCaptured
      end
    end
  end
  
  def test_raises_without_a_block
    pe = Tickly::NodeProcessor.new
    assert_raise(LocalJumpError) { pe.parse(NUKE7_SCRIPT) }
  end
  
  class Tracker3
    def initialize(n); end
  end
  
  def test_parses_huge
    pe = Tickly::NodeProcessor.new
    pe.add_node_handler_class(Tracker3)
    
    counter = 0
    pe.parse(HUGE_SCRIPT) do | t |
      counter += 1
    end
    assert_equal 45, counter
  end
end
