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
  
  def test_does_not_send_anything_when_the_expression_passed_does_not_match_pattern
    stack = e("ShouldNotBeInstantiated")
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
  
  def test_instantiates_handler_class
    stack = e("SomeNode", le(e("foo", "bar"), e("baz", "bad")))
    e = Tickly::Evaluator.new
    e.add_node_handler_class(SomeNode)
    node = e.evaluate(stack)
    
    assert_kind_of SomeNode, node
    ref_o = {"foo" => "bar", "baz" => "bad"}
    assert_equal ref_o, node.options
  end
  
  class TargetError < RuntimeError
  end
  
  def test_yields_the_handler_instance
    stack = e("SomeNode", le(e("foo", "bar"), e("baz", "bad")))
    e = Tickly::Evaluator.new
    e.add_node_handler_class(SomeNode)
    ref_o = {"foo" => "bar", "baz" => "bad"}
    
    assert_raise(TargetError) do
      e.evaluate(stack) do | some_node |
        assert_kind_of SomeNode, some_node
        raise TargetError
      end
    end
  end
  
  def test_will_capture
    e = Tickly::Evaluator.new
    e.add_node_handler_class(SomeNode)
    
    valid = e("SomeNode", le(e("foo", "bar"), e("baz", "bad")))
    assert e.will_capture?(valid)
    assert !e.will_capture?([])
    assert !e.will_capture?(e("SomeNode"))
  end

end
