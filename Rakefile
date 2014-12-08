# encoding: utf-8

require 'rubygems'
require 'bundler'
require File.dirname(__FILE__) + "/lib/tickly"

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.version = Tickly::VERSION
  gem.name = "tickly"
  gem.homepage = "http://github.com/julik/tickly"
  gem.license = "MIT"
  gem.summary = %Q{Assists in parsing Nuke scripts in TCL}
  gem.description = %Q{Parses the subset of the TCL grammar needed for Nuke scripts}
  gem.email = "me@julik.nl"
  gem.authors = ["Julik Tarkhanov"]
  # dependencies defined in Gemfile
  
  # Do not package test data
  gem.files.exclude "test/test-data/*.*"
end

Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "tickly #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "Profiles the parser"
task :profile do
  require 'ruby-prof'
  p = Tickly::NodeProcessor.new
  f = File.open(File.dirname(__FILE__) + "/test/test-data/huge_nuke_tcl.tcl")

  RubyProf.start
  p.parse(f) {|_| }
  result = RubyProf.stop

  # Print a call graph
  File.open("profiler_calls.html", "w") do | f |
    RubyProf::GraphHtmlPrinter.new(result).print(f)
  end
  `open profiler_calls.html`
end

