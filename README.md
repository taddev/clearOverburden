## Title: clearOverburden
**Avaliable at:** http://pastebin.com/VjcHyJbT

## Author: Tad DeVries <tad@splunk.net>
Copyright (C) 2013-2014 Tad DeVries <tad@splunk.net>
http://tad.mit-license.org/2014

## Description
This is a Mining Turtle program used to clear the overburden
when preparing to place a Buildcraft Quarry. The size is hard-coded to work
inside of a single chunk. The turtle will mine the entire 16x16x5 area needed
to build the Quarry framework. The reason for this is because I hate seeing
those resources get wasted when the Quarry *zaps* them.

## Use
1. Place the Turtle in the bottom left hand corner of the chuck you wish to
   operate inside of.
2. Place a chest directly behind the turtle to hold materials when they are
   returned from the mining operation.
3. Place a stack of fuel in the bottom right inventory slot.
4. Run the program

## Method of Operation
The Turtle will climb to the top layer of the area being mined and work its
way down from there. It will traverse each layer in a counter-clockwise
rotation changing its perspective of *bottom-left* as it goes. When a block
has filled every usable inventory slot it will return to the chest at the
origin and drop off everything in slots 1 through 15 then return to its last
known location to continue mining.

## Known Issues
### Mobs
There *could* be issues when encountering mobs. During testing 50 mobs where
spawned into the mining area and they were able to *trap* the turtle and
produce a java exception that aborted the program. Under normal operation
the turtle should be able to handle a couple mobs in the area. Each dig
operation is preceded by an attack attempt to simply push the mob out of the
way.