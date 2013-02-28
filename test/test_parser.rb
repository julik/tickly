require 'helper'

class TestParser < Test::Unit::TestCase
  P = Tickly::Parser.new
  
  should "parse a single int as a stack with a string" do
    assert_kind_of Tickly::LiteralExpr, P.parse('2')
    assert_equal ["2"], P.parse('2')
  end

  should "parse a single int and discard whitespace" do
    p = P.parse('   2 ')
    assert_kind_of Tickly::LiteralExpr, p
    assert_equal ["2"], p
    assert_equal "{2}", Tickly.to_tcl(p)
  end

  should "parse multiple ints and strings as a stack of subexpressions" do
    assert_kind_of Tickly::LiteralExpr, P.parse('2 foo bar baz')
    assert_equal ["2", "foo", "bar", "baz"], P.parse('2 foo bar baz')
  end
  
  should "parse and expand a string in double quotes" do
    p = P.parse('"This is a string literal with spaces"')
    assert_kind_of Tickly::LiteralExpr, p
    assert_equal ["This is a string literal with spaces"], p
    
    p = P.parse('"This is a string literal \"escaped\" with spaces"')
    assert_kind_of Tickly::LiteralExpr, p
    assert_equal ["This is a string literal \"escaped\" with spaces"], p
  end
  
  should "parse a string expression" do
    p = P.parse("[1 2 3]")
    assert_kind_of Tickly::LiteralExpr, p
    assert_equal 1, p.length
    assert_kind_of Tickly::StringExpr, p[0]
  end
  
  should "parse multiple string expressions" do
    p = P.parse("[1 2 3] [3 4 5 foo]")
    assert_equal ["3","4","5", "foo"], p[1]
    assert_equal "{[1 2 3] [3 4 5 foo]}", Tickly.to_tcl(p)
  end
  
  should "parse multiline statements as literal expressions" do
    p = P.parse("2\n2")
    assert_equal "{{2} {2}}", Tickly.to_tcl(p)
  end
  
  should 'parse expression' do
    expr = '{4 + 5}'
    p = P.parse(expr)
    assert_equal [["4", "+", "5"]], p
  end
  
  should 'parse a Nuke node' do
    f = File.open(File.dirname(__FILE__) + "/nukenode.txt")
    p = P.parse(f)
    script = [
      ["set", "cut_paste_input", ["stack", "0"]],
      ["version", "6.3", "v4"],
      ["push", "$cut_paste_input"],
      ["Blur", 
        [
          ["size", [["curve", "x1", "0", "x20", "1.7", "x33", "3.9"]]],
          ["name", "Blur1"],
          ["label", "With \"Escapes\""],
          ["selected", "true"],
          ["xpos", "-353"],
          ["ypos", "-33"]
        ]
      ]
    ]
    assert_equal script, p
  end
  
  should 'parse a simple Nuke script and internalize the RotoPaint in it' do
    f = File.open(File.dirname(__FILE__) + "/three_nodes_and_roto.txt")
    p = P.parse(f)
    # Should pass through the rotopaint node and get to the blur properly
    assert_equal ["Blur", [["size", [["curve", "i", "x1", "0", "x20", "1.7", "x33", "3.9"]]], ["name", "Blur1"], ["label", "With \"Escapes\""], ["selected", "true"], ["xpos", "-212"], ["ypos", "-24"]]], p[4]
  end
end
