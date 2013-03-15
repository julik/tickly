require 'helper'

if ENV['USER'] == 'julik'

  require 'ruby-prof'

  class TestProfile < Test::Unit::TestCase
    P = Tickly::Parser.new
  
  
    def test_huge_tcl
      f = File.open(File.dirname(__FILE__) + "/test-data/huge_nuke_tcl.tcl")
    
      RubyProf.start
      P.parse(f)
      result = RubyProf.stop
    
      # Print a call graph
      File.open("profiler_calls.html", "w") do | f |
        RubyProf::GraphHtmlPrinter.new(result).print(f)
      end
      `open profiler_calls.html`
    end
  
  end

end