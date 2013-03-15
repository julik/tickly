require File.dirname(__FILE__) + "/tickly/parser"
require File.dirname(__FILE__) + "/tickly/node_extractor"
require File.dirname(__FILE__) + "/tickly/evaluator"
require 'forwardable'

module Tickly
  VERSION = '0.0.7'
  
  # Provides the methods for quickly emitting the expression arrays,
  # is used in tests
  module Emitter
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
  
  # Converts a passed Array (received from a Parser)
  # into a TCL expression. This is only ever used in tests
  def self.to_tcl(e)
    if e.is_a?(Array) && e[0] == :c
      '{%s}' % e.map{|e| to_tcl(e)}.join(' ')
    elsif e.is_a?(Array) && e[0] == :b
      '[%s]' % e.map{|e| to_tcl(e)}.join(' ')
    elsif e.is_a?(Array)
      e.map{|e| to_tcl(e)}.join(" ")
    elsif e.is_a?(String) && (e.include?('"') || e.include?("'"))
      e.inspect
    else
      e.to_s
    end
  end
  
  
end
