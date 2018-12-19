require "bundler/gem_tasks"
require 'rake/testtask'

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "tickly #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "Benchmarks the parser"
task :bench do
  require File.dirname(__FILE__) + "/lib/tickly"
  require 'benchmark'

  class Tracker3
    def initialize(n); end
  end

  pe = Tickly::NodeProcessor.new
  pe.add_node_handler_class(Tracker3)
  
  HUGE_SCRIPT = File.open(File.dirname(__FILE__) + "/test/test-data/huge_nuke_tcl.tcl", "rb")
  Benchmark.bm do | runner |
    runner.report("Parsing a huge Nuke script:") do
      counter = 0
      pe.parse(HUGE_SCRIPT) { counter += 1 }
      HUGE_SCRIPT.rewind
    end
  end
end

task :default => [:test, :bench]
