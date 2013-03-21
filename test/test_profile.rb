require 'helper'

if ENV['USER'] == 'julik' && ENV['PROFILE_TICKLY']

  require 'ruby-prof'

  class TestProfile < Test::Unit::TestCase
    P = Tickly::NodeProcessor.new
  
  
    def test_huge_tcl
      f = File.open(File.dirname(__FILE__) + "/test-data/huge_nuke_tcl.tcl")
    
      RubyProf.start
      P.parse(f) {|_| }
      result = RubyProf.stop
    
      # Print a call graph
      File.open("profiler_calls.html", "w") do | f |
        RubyProf::GraphHtmlPrinter.new(result).print(f)
      end
      `open profiler_calls.html`
    end
  
  end

end