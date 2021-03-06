require File.dirname(__FILE__) + '/helper'

class TestParser < Test::Unit::TestCase
  P = Tickly::Parser.new
  
  def test_parse_single_int_as_a_stack_with_string_token
    assert_equal e(e("2")), P.parse('2')
  end

  def test_parse_single_int_and_discard_whitespace
    p = P.parse('   2 ')
    assert_equal e(e("2")), p
  end

  def test_parse_multiple_ints_and_strings_as_stack_of_expressions
    assert_equal e(e("2", "foo", "bar", "baz")), P.parse('2 foo bar baz')
  end
  
  def test_parse_and_expand_a_string_in_double_quotes
    p = P.parse('"This is a string literal with spaces"')
    assert_equal e(e("This is a string literal with spaces")), p
    
    p = P.parse('"This is a string literal \"escaped\" with spaces"')
    assert_equal e(e("This is a string literal \"escaped\" with spaces")), p
  end
  
  def test_parse_string_expression
    assert_equal e(e(se("1", "2", "3"))),  P.parse("[1 2 3]")
  end
  
  def test_parse_multiple_string_expressions_in_one_expression
    p = P.parse("[1 2 3] [3 4 5 foo]")
    assert_equal e(e(se("1", "2", "3"), se("3", "4", "5", "foo"))), p
  end
  
  def test_parse_multiline_statements_as_literal_expressions
    p = P.parse("2\n2")
    assert_equal e(e("2"), e("2")), p
  end
  
  def test_parse_expr
    expr = '{4 + 5}'
    p = P.parse(expr)
    assert_equal e(e(le("4", "+", "5"))), p
  end
  
  def test_raises_on_unterminated_string
    expr = '"Literal with no closing quote'
    assert_raise(Tickly::Parser::Error) { P.parse(expr) }
  end

  def test_raises_on_unterminated_subexpressions
    expr = 'a {b'
    assert_raise(Tickly::Parser::Error) { P.parse(expr) }
    
    expr = 'a [b'
    assert_raise(Tickly::Parser::Error) { P.parse(expr) }
  end
   
  def test_curlies_after_expr
    expr = 'a{4 + 5}b'
    p = P.parse(expr)
    assert_equal [["a", [:c, "4", "+", "5"], "b"]], p
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
  
  def test_parse_a_simple_Nuke_script_and_internalize_the_RotoPaint
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
  
  class Discarder < Tickly::Parser
    def compact_subexpr(expr, depth)
      return :discarded
    end
  end
  
  class Eater < Tickly::Parser
    def compact_subexpr(e, d)
      nil
    end
  end
  
  def test_passes_expressions_via_compact_subexpr
    f = File.open(File.dirname(__FILE__) + "/test-data/three_nodes_and_roto.txt")
    p = Discarder.new.parse(f)
    assert_equal [:discarded, :discarded, :discarded, :discarded, :discarded], p
  end
  
  def test_removes_all_the_expressions_compacted_into_nil
    f = File.open(File.dirname(__FILE__) + "/test-data/three_nodes_and_roto.txt")
    p = Eater.new.parse(f)
    assert_equal [], p
  end
  
  def test_parsing_nuke_script_with_shitdows_line_breaks
    f = File.open(File.dirname(__FILE__) + "/test-data/windows_linebreaks.nk")
    p = P.parse(f)
    
    first_expr = p[0]
    assert_equal ["set", "cut_paste_input", [:b, "stack", "0"]], first_expr, "Should have chopped off the <CR>"
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
    ref = e(e("SomeNode",
        le(
          e("foo", "bar")
        )
    ))
    
    assert_equal ref, p
  end
  
end
