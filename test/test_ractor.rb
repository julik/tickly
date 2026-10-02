require 'helper'

class TestRactor < Test::Unit::TestCase
  class Tracker4
    attr_reader :knobs
    def initialize(knobs)
      @knobs = knobs
    end
  end

  def test_parses_and_evaluates_inside_a_ractor
    omit "Needs Ruby 4.0+ Ractors" unless defined?(Ractor) && Ractor.method_defined?(:value)

    path = File.dirname(__FILE__) + "/test-data/nuke7_tracker_2tracks.nk"
    experimental_warnings, Warning[:experimental] = Warning[:experimental], false
    begin
      names = Ractor.new(path) do |script_path|
        pe = Tickly::NodeProcessor.new
        pe.add_node_handler_class(TestRactor::Tracker4)
        File.open(script_path, "rb") do |f|
          nodes = []
          pe.parse(f) { |node| nodes << node.knobs["name"] }
          nodes
        end
      end.value
      assert_equal ["Tracker1"], names
    ensure
      Warning[:experimental] = experimental_warnings
    end
  end
end
