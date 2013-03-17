require File.dirname(__FILE__) + "/tickly/parser"
require File.dirname(__FILE__) + "/tickly/node_extractor"
require File.dirname(__FILE__) + "/tickly/evaluator"
require 'forwardable'

module Tickly
  VERSION = '0.0.8'
  
  # Provides the methods for quickly emitting the expression arrays,
  # is used in tests
  module Emitter #:nodoc :all
    def le(*elems)
      [:c] + elems
    end
    
    def e(*elems)
      elems
    end
    
    def se(*elems)
      [:b] + elems
    end
  end
  
end
