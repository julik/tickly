require 'helper'

class TestSplitArray < Test::Unit::TestCase
  should "return a standard array unscathed" do
    assert_equal [1, 2, 3, 4], Tickly.split_array([1,2,3,4])
  end
  
  should "return a split array on nil" do
    assert_equal [[1, 2],  [3, 4]], Tickly.split_array([1, 2, nil,  3, 4])
  end
  
  should "only generate sub-elements where they make sense" do
    assert_equal [[1, 2]], Tickly.split_array([nil, 1, 2, nil])
  end
  
  class Jock < Array; end
  
  should "properly use subclasses" do
    s =  Tickly.split_array(Jock.new([1, 2, nil,  3, 4]))
    assert_kind_of Jock, s
    assert_kind_of Jock, s[0]
  end
  
  should 'squeeze nils out' do
    s = Tickly.singularize_nils_in([nil, nil, 1,2,3,4, nil, nil, 456, nil, 9,nil,nil])
    assert_equal [nil, 1,2,3,4, nil, 456, nil, 9, nil], s
  end
end
