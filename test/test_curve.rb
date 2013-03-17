require "helper"

class TestCurve < Test::Unit::TestCase
  def test_parsing_nuke_curve
    curve = [:c] + %w( curve x742 888 890.2463989 891.6602783 
893.5056763 895.6155396 s95 897.2791748 899.1762695 
x754 912.0731812 x755 913.7190552 916.0959473 918.1025391 920.0751953 922.1898804 )
    
    p = Tickly::Curve.new(curve)
    result = p.to_a
    
    assert_kind_of Array, result
    assert_equal 13, result.length
    assert_equal 742, result[0][0]
    assert_equal 754, result[7][0]
  end
  
  def test_invalid_curves
    assert_raise Tickly::Curve::InvalidCurveError do
      Tickly::Curve.new([])
    end
    
    assert_raise Tickly::Curve::InvalidCurveError do
      Tickly::Curve.new([:c])
    end
    
    assert_raise Tickly::Curve::InvalidCurveError do
      Tickly::Curve.new([:c, "curve"])
    end
  end
end