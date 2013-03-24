require 'helper'
require 'benchmark'

class TestParserEvaluator < Test::Unit::TestCase
  
  class Tracker3
    def initialize(n); end
  end

  def test_parses_huge
    pe = Tickly::NodeProcessor.new
    pe.add_node_handler_class(Tracker3)
    
    Benchmark.bm do | runner |
      runner.report("Parsing a huge Nuke script:") do
        counter = 0
        pe.parse(HUGE_SCRIPT) { counter += 1 }
      end
    end
  end
end
