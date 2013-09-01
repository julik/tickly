module Tickly
  # A shorthand class for Nuke's animation curves.
  # Will convert a passed Curve expression into a set of values,
  # where all the values are baked per integer frames on the whole
  # stretch of time where curve is defined
  class Curve
    
    class InvalidCurveError < RuntimeError; end
    
    include Enumerable
    
    SECTION_START = /^x(\d+)$/
    KEYFRAME = /^([-\d\.]+)$/
    
    # The constructor accepts a Curve expression as returned by the Parser
    # Normally it looks like this
    #     [:c, "curve", "x1", "123", "456", ...]
    def initialize(curve_expression)
      raise InvalidCurveError, "A curve expression should have :c as it's first symbol" unless curve_expression[0] == :c
      raise InvalidCurveError, "Curve expression contained no values" unless curve_expression[2]
      
      # Nuke7 sometimes produces curves where the command is a string literal 
      # within quotes, and it contains a trailing space
      cmd = curve_expression[1].to_s.strip
      raise InvalidCurveError, "Curve expression should start with a 'curve' command" unless cmd == 'curve'
      
      
      expand_curve(curve_expression)
    end
    
    # Returns each defined keyframe as a pair of a frame number and a value
    def each(&blk)
      @tuples.each(&blk)
    end
    
    private
    
    def expand_curve(curve_expression)
      # Replace the closing curly brace with a curly brace with space so that it gets caught by split
      atoms = curve_expression[2..-1] # remove the :c curly designator and the "curve" keyword
      
      @tuples = []
      # Nuke saves curves very efficiently. x(keyframe_number) means that an uninterrupted sequence of values will start,
      # after which values follow. When the curve is interrupted in some way a new x(keyframe_number) will signifu that we
      # skip to that specified keyframe and the curve continues from there, in gap size defined by the last fragment.
      # That is, x1 1 x3 2 3 4 will place 2, 3 and 4 at 2-frame increments.
      # Thanks to Michael Lester for explaining this.
      last_processed_keyframe = 1
      intraframe_gap_size = 1
      while atom = atoms.shift
        if atom =~ SECTION_START
          last_processed_keyframe = $1.to_i
          if @tuples.any?
            last_captured_frame = @tuples[-1][0]
            intraframe_gap_size = last_processed_keyframe - last_captured_frame
          end
        elsif  atom =~ KEYFRAME
          @tuples << [last_processed_keyframe, $1.to_f]
          last_processed_keyframe += intraframe_gap_size
        end
      end
    end
  end
end