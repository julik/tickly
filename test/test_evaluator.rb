require 'helper'

class TestEvaluator < Test::Unit::TestCase
  include Tickly::Emitter
  
  should "not do anything without handlers" do
    stack = le("Tracker4", le(le("enabled", "true")))
    e = Tickly::Evaluator.new
    e.evaluate(stack)
  end

  class ShouldNotBeInstantiated
    def initialize
      raise "You failed"
    end
  end
  
  should "not send anything to the handler when the expr does not conform to the standard" do
    stack = le("ShouldNotBeInstantiated")
    e = Tickly::Evaluator.new
    e.add_node_handler_class(ShouldNotBeInstantiated)
    assert_nothing_raised { e.evaluate(stack) }
  end
  
  class SomeNode
    attr_reader :options
    def initialize(options_hash)
      @options = options_hash
    end
  end
  
  should "instantiate the handler class" do
    stack = le("SomeNode", le(le("foo", "bar"), le("baz", "bad")))
    e = Tickly::Evaluator.new
    e.add_node_handler_class(SomeNode)
    node = e.evaluate(stack)
    
    assert_kind_of SomeNode, node
    ref_o = {"foo" => "bar", "baz" => "bad"}
    assert_equal ref_o, node.options
  end

end
