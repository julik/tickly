require File.dirname(__FILE__) + "/tickly/parser"
require File.dirname(__FILE__) + "/tickly/evaluator"
require 'forwardable'

module Tickly
  VERSION = '0.0.3'
  
  # Provides the methods for quickly emitting the LiteralExpr and StringExpr objects
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
  
  def self.to_tcl(e)
    if e.is_a?(Array) && e[0] == :c
      '{%s}' % e.map{|e| to_tcl(e)}.join(' ')
    elsif e.is_a?(Array) && e[0] == :b
      '[%s]' % e.map{|e| to_tcl(e)}.join(' ')
    elsif e.is_a?(String) && (e.include?('"') || e.include?("'"))
      e.inspect
    else
      e.to_s
    end
  end
  
  # Splits the passed Array-like object into sub-arrays of the same class,
  # delimited by the passed separator. Note that when the separators occur at the beginning or at the end of
  # the passed object they will be discarded
  def self.split_array(arr, separator = nil)
    return arr unless arr.include?(separator)
    
    subarrays = arr.class.new
    subarrays.push(arr.class.new)
    
    arr.each_with_index do | element, i |
      if element == separator && subarrays.length > 0 && subarrays[-1].any? && (i < (arr.length - 1))
        subarrays.push(arr.class.new)
      elsif element == separator
        # toss it
      else
        subarrays[-1].push(element)
      end
    end
    return subarrays
  end
  
end
