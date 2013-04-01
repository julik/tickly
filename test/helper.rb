require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'tickly'

class Test::Unit::TestCase
  # Provides the methods for quickly emitting the expression arrays,
  # is used in tests
  module Emitter #:nodoc :all
    def le(*elems)
      e(*elems).unshift :c
    end
    
    def e(*elems)
      elems
    end
    
    def se(*elems)
      e(*elems).unshift :b
    end
  end
  
  include Emitter
end
