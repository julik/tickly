require File.dirname(__FILE__) + "/tickly/parser"

module Tickly
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
    
    arr.each do | element |
      if element == separator
        subarrays.push(arr.class.new)
      else
        subarrays[-1].push(element)
      end
    end
    return subarrays
  end
end
