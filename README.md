[![Build Status](https://travis-ci.org/julik/tickly.svg?branch=master)](https://travis-ci.org/julik/tickly)

A highly simplistic TCL parser and evaluator (primarily designed for parsing Nuke scripts).
It transforms the passed Nuke scripts into a TCL AST. 
It also supports some cheap tricks to discard the nodes you are not interested in, since Nuke
scripts easily grow into tens of megabytes.

The AST format is extremely simple (nested arrays).

## Plain parsing

Create a Parser object and pass TCL expressions/scripts to it. You can pass IO obejcts or strings. Note that parse()
will always return an Array of expressions, even if you only fed it one expression line. For example:
    
    p = Tickly::Parser.new
    
    # One expression, even if it's invalid (2 is not a valid TCL bareword - doesn't matter)
    p.parse '2' #=> [["2"]]
    
    # TCL command
    p.parse "tail $list" #=> [["tail", "$list"]]
    
    # Multiple expressions
    p.parse "2\n2" #=> [["2"], ["2"]]
    
    # Expressions in curly braces   
    p.parse '{2 2}' #=> [[:c, "2", "2"]]
    
    # Expressions in square brackets
    p.parse '{exec cmd [fileName]}' #=> [[:c, "exec", "cmd", [:b, "fileName"]]]

The AST is represented by simple arrays. Each TCL expression becomes an array. An array starting 
with the `:c` symbol ("c" for "curlies") is a literal expression in curly braces (`{}`). 
An array with the `:b` symbol at the beginning is an expression with string interpolations 
(square brackets).
All the other array elements are guaranteed to be strings or innner expressions (arrays).

String literals are expanded to string array elements.

    p.parse( '"a string with \"quote"') #=> [['a string with "quote']]

Multiple expressions separated by semicolons or newlines will be accumulated as multiple arrays.

Lots and lots of TCL features are probably not supported - remember that most Nuke scripts are 
machine-generated and they do not use most of the esoteric language features.

## Evaulating nodes in Nuke scripts

What you are likely to use Tickly for is parsing Nuke scripts. They got multiple node definitions, which
are actially arguments for a node constructor written out in TCL. Consider this ubiquitous fragment for a
hypothetic SomeNode in your script:

    SomeNode {
      name SomeNode4
      someknob 15
      anotherknob 3
      animation {curve x1 12 45 67}
      x_pos 123
      y_pos -10
    }

and so on. You can use a `NodeProcessor` to capture these node constructors right as they are being parsed.
The advantage of this workflow is that the processor will discard all the nodes you don't need, saving time
and memory.

To match nodes you create Ruby classes matching the node classes by name. It doesn't matter if your
custom node handler is inside a module since the processor will only use the last part of the name.

For example, to capture every `Blur` node in your script:
    
    # Remember, only the last part of the class name matters
    class MyAwesomeDirtyScript::Blur
      attr_reader :knobs
      def initialize(string_keyed_knobs_hash)
        @knobs = string_keyed_knobs_hash
      end
    end
    
    # Instantiate a new processor
    e = Tickly::NodeProcessor.new
    
    # Add the class
    e.add_node_handler_class SomeNode
    
    # Open the ginormous Nuke script
    file = File.open("/mnt/raid/nuke/scripts/HugeShot_123.nk")
    
    e.parse(file) do | blur_node |
      # Everytime a Blur node is found in the script it will be instantiated,
      # and the knobs of the node will be passed to the constructor that you define
      kernel_size = blur_node.knobs["radius"]
      ...
    end

Of course you can capture multiple node classes. This is how Tracksperanto parses various
nodes containing tracking data:
    
    parser = Tickly::NodeProcessor.new
    parser.add_node_handler_class(Tracker3)
    parser.add_node_handler_class(Reconcile3D)
    parser.add_node_handler_class(PlanarTracker1_0)
    parser.add_node_handler_class(Tracker4)

Then you will need to handle switching between node types during parsing

    e.parse(file) do | detected_node |
      if detected_node.is_a?(Tracker3)
	    ...
	  else
	    ...
	  end
    end

Node clones are not supported.

## Animation curves

You can parse Nuke's animation curves using `Tickly::Curve`. This will give you a way to iterate over every defined keyframe.
This currently does not happen automatically for things passing through the parser.

## Tip: Speeding up parsing

Normally, Tickly will accept strings and IO objects as sources. However if you want a little performance boost
when parsing actual _files_ (or long IO objects that can be prebuffered) you should use it together
with [bychar](http://rubygems.org/gems/bychar), version 3 or newer - like so:

    p = Tickly::Parser.new
    File.open("/mnt/raid/comps/s023_v23.nk", "r") do | f |
	  expressions = p.parse(Bychar.wrap(f))
	  ...
	end
	
This way some of the IO will be prebuffered for you and give you improved reading performance when parsing.

Tracksperanto does the bychar wrapping thing automatically, so no need to worry about that.



## Contributing to tickly

Just like tracksperanto Tickly no longer ships with test data in gem format (since the test data amounts to
to a substantial increase in package size). To obtain the test data, check the repo out.
 
* Check out the latest master to obtain the test data.
* Make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2013 Julik Tarkhanov. See LICENSE.txt for
further details.

