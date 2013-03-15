require 'helper'
require 'ruby-prof'

class TestProfile < Test::Unit::TestCase
  P = Tickly::Parser.new
  
  def test_huge_tcl
    f = File.open(File.dirname(__FILE__) + "/test-data/huge_nuke_tcl.tcl")
    
    RubyProf.start
    P.parse(f)
    result = RubyProf.stop
    
    # Print a flat profile to text
    printer = RubyProf::FlatPrinter.new(result)
    printer.print($stderr)
  end
  
end
