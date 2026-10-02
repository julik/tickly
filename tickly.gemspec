require File.dirname(__FILE__) + '/lib/tickly/version'

Gem::Specification.new do |s|
  s.name = "tickly"
  s.version = Tickly::VERSION

  s.required_ruby_version = ">= 2.6"
  s.require_paths = ["lib"]
  s.authors = ["Julik Tarkhanov"]
  s.date = Time.now.utc.strftime("%Y-%m-%d")
  s.description = "Parses the subset of the TCL grammar needed for Nuke scripts"
  s.email = "me@julik.nl"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = `git ls-files -z`.split("\x0").reject do |f|
    f.start_with? "test/test-data/"
  end
  s.homepage = "http://github.com/julik/tickly"
  s.licenses = ["MIT"]
  s.summary = "Assists in parsing Nuke scripts in TCL"

  s.add_development_dependency("rake")
  s.add_development_dependency("rdoc")
  s.add_development_dependency("benchmark")
  s.add_development_dependency("test-unit")
end
