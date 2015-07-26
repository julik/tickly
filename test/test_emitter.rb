require "helper"

class TestEmitter < Test::Unit::TestCase
  def test_emitter_e
    assert_equal ["2", "2"], e("2", "2")
  end
  
  def test_emitter_le
    assert_equal [:c, "2", "2"], le("2", "2")
  end
  
  def test_emitter_be
    assert_equal [:b, "2", "2"], se("2", "2")
  end
  
  def test_emitter_be_with_subexpression
    assert_equal [:b, [:c,"2", "2"]], se(le("2", "2"))
  end
  
end