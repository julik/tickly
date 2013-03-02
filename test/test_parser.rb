require 'helper'

class TestParser < Test::Unit::TestCase
  P = Tickly::Parser.new
  include Tickly::Emitter
  
  should "parse a single int as a stack with a string" do
    assert_kind_of Tickly::LiteralExpr, P.parse('2')
    assert_equal le("2"), P.parse('2')
  end

  should "parse a single int and discard whitespace" do
    p = P.parse('   2 ')
    assert_kind_of Tickly::LiteralExpr, p
    assert_equal le("2"), p
    assert_equal "{2}", Tickly.to_tcl(p)
  end

  should "parse multiple ints and strings as a stack of subexpressions" do
    assert_kind_of Tickly::LiteralExpr, P.parse('2 foo bar baz')
    assert_equal le("2", "foo", "bar", "baz"), P.parse('2 foo bar baz')
  end
  
  should "parse and expand a string in double quotes" do
    p = P.parse('"This is a string literal with spaces"')
    assert_equal le("This is a string literal with spaces"), p
    
    p = P.parse('"This is a string literal \"escaped\" with spaces"')
    assert_equal le("This is a string literal \"escaped\" with spaces"), p
  end
  
  should "parse a string expression" do
    p = P.parse("[1 2 3]")
    assert_kind_of Tickly::LiteralExpr, p
    assert_equal 1, p.length
    assert_kind_of Tickly::StringExpr, p[0]
  end
  
  should "parse multiple string expressions" do
    p = P.parse("[1 2 3] [3 4 5 foo]")
    assert_equal le(se("1", "2", "3"), se("3", "4", "5", "foo")), p
  end
  
  should "parse multiline statements as literal expressions" do
    p = P.parse("2\n2")
    assert_equal "{{2} {2}}", Tickly.to_tcl(p)
  end
  
  should 'parse expression' do
    expr = '{4 + 5}'
    p = P.parse(expr)
    assert_equal le(le("4", "+", "5")), p
  end
  
  should 'parse a Nuke node' do
    f = File.open(File.dirname(__FILE__) + "/nukenode.txt")
    p = P.parse(f)
    script = le(
      le("set", "cut_paste_input", se("stack", "0")),
      le("version", "6.3", "v4"),
      le("push", "$cut_paste_input"),
      le("Blur",
        le(
          le("size", 
            le(
              le("curve", "x1", "0", "x20", "1.7", "x33", "3.9")
            )
          ),
          le("name", "Blur1"),
          le("label", "With \"Escapes\""),
          le("selected", "true"),
          le("xpos", "-353"),
          le("ypos", "-33")
        )
      )
    )
    assert_equal script, p
  end
  
  should 'parse a simple Nuke script and internalize the RotoPaint in it' do
    f = File.open(File.dirname(__FILE__) + "/three_nodes_and_roto.txt")
    p = P.parse(f)
    # Should pass through the rotopaint node and get to the blur properly
    blur = le("Blur", 
      le(
        le("size", 
          le(
            le("curve", "i", "x1", "0", "x20", "1.7", "x33", "3.9")
            )
          ),
        le("name", "Blur1"),
        le("label", "With \"Escapes\""),
        le("selected", "true"),
        le("xpos", "-212"),
        le("ypos", "-24")
      )
    )
    assert_equal blur, p[4]
  end
  
  should 'parse a Nuke script with indentations' do
    f = File.open(File.dirname(__FILE__) + "/nuke_group.txt")
    p = P.parse(f)
    grp = le(
      le("set", "cut_paste_input", se("stack", "0")),
      le("version", "6.3", "v4"),
      le("Group",
        le(
          le("inputs", "0"),
          le("name", "Group1"),
          le("selected", "true")
          )
        ),
      le("CheckerBoard2",
        le(
          le("inputs", "0"),
          le("name", "CheckerBoard1")
        )
      ),
      le("Blur",
        le(
          le("size", "42.5"),
          le("name", "Blur1")
        )
      ),
      le("Output",
        le("name", "Output1")
      ),
      le("end_group")
    )
    assert_equal grp, p
  end
end
