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
  
  def test_curve_plus
    curve = [:c] + %w( curve+5 x1 987 x32 989.5999756 )
      
    p = Tickly::Curve.new(curve)
    result = p.to_a
    assert_kind_of Array, result
    assert_equal [[1, 992.0], [32, 994.5999756]], result
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
  
  def test_curve_with_trailing_space_at_command_end
    atoms = [:c, "curve ", "x374", "1008.35", "899.289", "809.798", 
        "742.572", "825.061", "1013.43", "1238.31", "1490.91", 
        "1698.4", "1848.96", "1889.24", "1961.12", "2024.13", 
        "2090.3", "2114.74", "2164.57", "2227.17", "2309.3"]
    
    c = Tickly::Curve.new(atoms)
    assert_kind_of Tickly::Curve, c
  end
end