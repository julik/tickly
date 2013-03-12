require 'helper'

class TestParser < Test::Unit::TestCase
  P = Tickly::Parser.new
  include Tickly::Emitter
  
  should "parse a single int as a stack with a string" do
    assert_equal e("2"), P.parse('2')
  end

  should "parse a single int and discard whitespace" do
    p = P.parse('   2 ')
    assert_equal e("2"), p
  end

  should "parse multiple ints and strings as a stack of subexpressions" do
    assert_equal e("2", "foo", "bar", "baz"), P.parse('2 foo bar baz')
  end
  
  should "parse and expand a string in double quotes" do
    p = P.parse('"This is a string literal with spaces"')
    assert_equal e("This is a string literal with spaces"), p
    
    p = P.parse('"This is a string literal \"escaped\" with spaces"')
    assert_equal e("This is a string literal \"escaped\" with spaces"), p
  end
  
  should "parse a string expression" do
    assert_equal e(se("1", "2", "3")),  P.parse("[1 2 3]")
  end
  
  should "parse multiple string expressions" do
    p = P.parse("[1 2 3] [3 4 5 foo]")
    assert_equal e(se("1", "2", "3"), se("3", "4", "5", "foo")), p
  end
  
  def test_parse_multiline_statements_as_literal_expressions
    p = P.parse("2\n2")
    assert_equal e(e("2"), e("2")), p
  end
  
  def test_parse_expr
    expr = '{4 + 5}'
    p = P.parse(expr)
    assert_equal e(le("4", "+", "5")), p
  end
  
  def test_parsing_a_nuke_node
    f = File.open(File.dirname(__FILE__) + "/test-data/nukenode.txt")
    p = P.parse(f)
    script = e(
      e("set", "cut_paste_input", se("stack", "0")),
      e("version", "6.3", "v4"),
      e("push", "$cut_paste_input"),
      e("Blur",
        le(
          e("size", 
            le(
              le("curve", "x1", "0", "x20", "1.7", "x33", "3.9")
            )
          ),
          e("name", "Blur1"),
          e("label", "With \"Escapes\""),
          e("selected", "true"),
          e("xpos", "-353"),
          e("ypos", "-33")
        )
      )
    )
    assert_equal script, p
  end
  
  should 'parse a simple Nuke script and internalize the RotoPaint in it' do
    f = File.open(File.dirname(__FILE__) + "/test-data/three_nodes_and_roto.txt")
    p = P.parse(f)
    # Should pass through the rotopaint node and get to the blur properly
    blur = e("Blur", 
      le(
        e("size", 
          le(
            le("curve", "i", "x1", "0", "x20", "1.7", "x33", "3.9")
            )
          ),
        e("name", "Blur1"),
        e("label", "With \"Escapes\""),
        e("selected", "true"),
        e("xpos", "-212"),
        e("ypos", "-24")
      )
    )
    assert_equal blur, p[4]
  end
  
  def test_parsing_nuke_script_with_indentations
    f = File.open(File.dirname(__FILE__) + "/test-data/nuke_group.txt")
    p = P.parse(f)
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
      e("CheckerBoard2",
        le(
          e("inputs", "0"),
          e("name", "CheckerBoard1")
        )
      ),
      e("Blur",
        le(
          e("size", "42.5"),
          e("name", "Blur1")
        )
      ),
      e("Output",
        le(
          e("name", "Output1")
        )
      ),
      e("end_group")
    )
    assert_equal grp, p
  end
  
  def test_one_node_parsing
    f = File.open(File.dirname(__FILE__) + "/test-data/one_node_with_one_param.txt")
    p = P.parse(f)
    ref = e("SomeNode",
        le(
          e("foo", "bar")
        )
    )
    
    assert_equal ref, p
  end
  
end
