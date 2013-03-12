require 'helper'

class TestNodeExtractor < Test::Unit::TestCase
  
  include Tickly::Emitter
  
  def test_parsing_nuke_script_with_indentations
    f = File.open(File.dirname(__FILE__) + "/test-data/nuke_group.txt")
    x = Tickly::NodeExtractor.new("Group")
    
    p = x.parse(f)
    grp = e(
      e("set", "cut_paste_input", se("stack", "0")),
      e("version", "6.3", "v4"),
      e("Group",
        le(
          e("inputs", "0"),
          e("name", "Group1"),
          e("selected", "true")
          )
        ),
      e(:discarded),
      e(:discarded),
      e(:discarded),
      e("end_group")
    )
    assert_equal grp, p
  end
  
end
