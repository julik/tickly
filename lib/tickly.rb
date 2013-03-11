require File.dirname(__FILE__) + "/tickly/parser"
require File.dirname(__FILE__) + "/tickly/evaluator"
require 'forwardable'

module Tickly
  VERSION = '0.0.3'
  
  # Represents a TCL expression with it's arguments (in curly or square braces)
  class Expr
    extend Forwardable
    
    def_delegators :@e, :push, :<<, :any?, :reject!, :map!, :[], :delete_at, :include?, :each, :each_with_index, :empty?, :join, :length
    
    def initialize(elements = [])
      @e = elements
    end
    
    def map(&blk)
      self.class.new(@e.map(&blk))
    end
    
    def to_a
      @e
    end
    
    def ==(another)
      another.to_a == to_a
    end
    
    def inspect
      @e.map{|e| e.inspect }.join(', ')
    end
    
  end
  
  # Represents an expression between curly braces (within which no text substitution will be done)
  # like  { 1 2 3 }
  class LiteralExpr < Expr
    def inspect
      "le(%s)" % super
    end
  end

  # Represents an expression between square brackets (where text substitution will be done)
  # like  [1 2 3]
  class StringExpr < Expr
    def inspect
      "se(%s)" % super
    end
  end
  
  # Provides the methods for quickly emitting the LiteralExpr and StringExpr objects
  module Emitter
    def le(*elems)
      LiteralExpr.new(elems)
    end
    
    def se(*elems)
      LiteralExpr.new(elems)
    end
  end
  
  
  def self.to_tcl(e)
    if e.is_a?(Tickly::LiteralExpr)
      '{%s}' % e.map{|e| to_tcl(e)}.join(' ')
    elsif e.is_a?(Tickly::StringExpr)
      '[%s]' % e.map{|e| to_tcl(e)}.join(' ')
    elsif e.is_a?(String) && (e.include?('"') || e.include?("'"))
      e.inspect
    else
      e.to_s
    end
  end
  
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
  
  def self.singularize_nils_in(arr)
    new_arr = arr.class.new
    arr.each_with_index do | elem, i |
      if elem.nil? && arr[i-1].nil? && i > 0
        # pass
      else
        new_arr << elem
      end
    end
    new_arr
  end
  
end
