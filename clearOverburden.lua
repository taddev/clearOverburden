-- ############################################################################
-- Title: clearOverburden
--
-- Author: Tad DeVries <tad@splunk.net>
--
-- Copyright (C) 2013-2014 Tad DeVries <tad@splunk.net>
-- http://tad.mit-license.org/2014
--
-- Description:
-- This is a Mining Turtle program used to clear the overburden
-- when preparing to place a Buildcraft Quarry. The size is hardcoded to work
-- inside of a single chuck. The turtle will mine the entire 16x16x5 area needed
-- to build the Quarry framework. The reason for this is because I hate seeing
-- those resources get wasted when the Quarry *zaps* them.
--
-- Use:
-- 1. Place the Turtle in the bottom left hand corner of the chuck you wish to
--    operate inside of.
-- 2. Place a chest direction behind the turtle to hold materials when they are
--    returned from the mining operation.
-- 3. Place a stack of fuel, perferably coal, in the bottom right inventory
--    slot; spot 16.
-- 4. Run the program
--
-- Method of Operation:
-- The Turtle will climb to the top layer of the area being mined and work its
-- way down from there. It will traverse each layer in a counter-clockwise
-- rotation changing its perspective of *bottom-left* as it goes. When a block
-- has filled every usable inventory slot it will return to the chest at the
-- origin and drop off everything in slots 1 through 15 then return to its last
-- known location to continue mining.
--
-- Known Issues:
-- There could be issues when encountering mobs. During testing 50 mobs where
-- spawned into the mining area and they were able to *trap* the turtle and
-- produce a java exception that aborted the program. Under normal operation
-- the turtle should be able to handle a couple mobs in the area. Each dig
-- operation is preceded by an attack attempt to simply push the mob out of the
-- way.
--
-- The reOrient function does not produce an optimal turning mechanism. It
-- always turns right to get the to desired orientation so there is some
-- needless turning but it works for now.
--
-- ############################################################################



-- define orientations
Direction = {FORWARD=0, RIGHT=1, BACK=2, LEFT=3}
Position = {Row=0, Column=0, Layer=0, Orientation=0}
SavedPosition = {}

QuarryFrameHeight = 4
QuarryFrameWidth = 15
QuarryFrameDepth = 15


FuelSlot = 16
MaxDig = 25

--
-- Search through the turtles inventory looking for anything that
-- might be used as fuel and use it.
function findFuel()
	for i = 1, 16 do
		turtle.select(i)
		if turtle.refuel(0) then
			return i
		end
	end
	return 0
end

--
-- Check the fuel level and fill it up if it's empty
--
function checkFuel()
	if turtle.getFuelLevel() < 1 then
		fillFuel()
	end
end

--
-- Comsume one piece of fuel from slot 16. If there is no fuel in slot 16 then
-- look for something usable as fuel in the rest of the iventory.
--
function fillFuel()
	turtle.select(FuelSlot)

	if not turtle.refuel(0) then
		FuelSlot = findFuel()
	end

	if FuelSlot ~= 0 then
		turtle.select(FuelSlot)
		turtle.refuel(1)
	else
		print("No Fuel Found")
	end
end

--
-- Check the inventory to see if all slots have something in them
-- If they do then return to the origin location top dump the inventory
-- then return to mining
--
function checkInventory()
	local usedSlots = 0

	for i=1, 15 do
		if turtle.getItemCount(i) > 0 then
			usedSlots = usedSlots + 1
		end
	end

	if usedSlots >= 15 then
		--- return to empty invetory
		print("Inventory Full")
		local layer = Position.Layer % 4
		local bottom = 0
		local left = 0

		bottom, left = findBottomLeft(layer)
		returnToOrigin(layer, bottom, left)
		emptyInventory()
		returnToMine(layer, bottom, left)
	end
end

--
-- Generic Dig Function
--
function turtleDig(detectFn, digFn)
	local digCount = 0
	checkInventory()

	while detectFn() and (digCount < MaxDig) do
		digFn()
		digCount = digCount + 1
	end
end

--
-- Generic Move Function
--
function turtleMove(moveFn,  detectFn, digFn, attackFn)
	checkFuel()

	while not moveFn() do
		attackFn()
		turtleDig(detectFn, digFn)
	end
end

--
--  Dig forward then try to move and dig again if neccesary
--
function driveFoward()
	turtleMove(turtle.forward, turtle.detect, turtle.dig, turtle.attack)
end

--
-- Dig up then try to move and dig again if neccesary
--
function driveUp()
	turtleMove(turtle.up, turtle.detectUp, turtle.digUp, turtle.attackUp)
end

--
-- Dig down then move
--
function driveDown()
	turtleMove(turtle.down, turtle.detectDown, turtle.digDown, turtle.attackDown)
end

--
-- Turn Right and update orientation
--
function turnRight()
	turtle.turnRight()
	Position.Orientation = (Position.Orientation+1) % 4
end

--
-- Turn Left and update orientation
--
function turnLeft()
	turtle.turnLeft()

	-- Special case if we're facing forward to start with then
	-- just set the new orientaion left to eliminate the possibility
	-- of a negative number
	if Position.Orientation == Direction.FORWARD then
		Position.Orientation = Direction.LEFT
	else
		Position.Orientation = (Position.Orientation-1) % 4
	end
end

--
-- Turn the turle till it faces the way we want
-- I could get fancy here but just keep turning
-- right until we're the correct way
--
function reOrient(newOrientation)
	while Position.Orientation ~= newOrientation do
		turnRight()
	end

	Position.Orientation = newOrientation
end

--
-- Move forward a specific number of spaces
-- Return the number of spaces moved for verification
--
function moveForward(requiredMoves)
        local moves = 0
        for i=1, requiredMoves do
            driveFoward()
            Position.Row = Position.Row + 1
        end
end

--
-- Move right one space turning around in the process
--
function moveRight()
	checkInventory()
	turnRight()
	driveFoward()
	turnRight()
end

--
-- Move left one space turning around in the process
--
function moveLeft()
	checkInventory()
	turnLeft()
	driveFoward()
	turnLeft()
end

--
-- Move up one space turning to the right once
--
function moveUp()
	turnRight()
	driveUp()
end

--
-- Move Down
--
function moveDown()
	checkInventory()
	turnRight()
	driveDown()
end

--
-- Clears one layer starting in the *bottom left* and working toward
-- the *bottom right*.
--
function clearLayer()
	local actualMoves = 0
	local requiredMoves = 0

	while Position.Column <= QuarryFrameWidth do
		print("Clearing Column", Position.Column)

		moveForward(QuarryFrameDepth)

		if Position.Column ~= QuarryFrameWidth then
			if Position.Column%2 == 0 then
				moveRight()
			else
				moveLeft()
			end
		end

		Position.Row = 0
		Position.Column = Position.Column + 1
	end
end

--
-- Find the distance to therelaitive bottom-left for each mining layer
--
function findBottomLeft(layer)
	local left = 0
	local bottom = 0

	if layer == 0 then
		left = Position.Column
		bottom = Position.Row

		if Position.Orientation == Direction.BACK then
			bottom = QuarryFrameDepth - bottom
		end
	elseif layer == 3 then
		left = Position.Row
		bottom = Position.Column

		if Position.Orientation == Direction.LEFT then
			left = QuarryFrameWidth - left
		end
	elseif layer == 2 then
		left = QuarryFrameWidth - Position.Column
		bottom = Position.Row

		if Position.Orientation == Direction.BACK then
			bottom = QuarryFrameDepth - bottom
		end
	elseif layer == 1 then
		left = Position.Row
		bottom = QuarryFrameDepth - Position.Column

		if Position.Orientation == Direction.LEFT then
			left = QuarryFrameWidth - Position.Row
		end
	else
		print("Error finding bottom-left")
		os.exit()
	end

	return bottom, left
end

--
-- The basic steps needed to return to the origin. It's a bit tricky since we
-- don't always mine in the same direction
--
-- 1a: Go up if neccessary
-- 1: ReOrient to the LEFT
-- 2: Drive to the left
-- 3: Drive to the bottom
-- 4a: Go down if neccessary
-- 4: Empty inventory into chest
-- 5: Return to mining, undo moves to get here
--
function returnToOrigin(layer, bottom,left)
	-- save the current position
	for key, value in pairs(Position) do
		SavedPosition[key] = value
	end

	-- 1a:
	if layer ~= 0 then
		driveUp()
		Position.Layer = Position.Layer+1
	end

	-- 1:
	reOrient(Direction.LEFT)

	-- 2:
	moveForward(left)

	-- 3:
	turnLeft()
	moveForward(bottom)

	-- 4a:
	while Position.Layer > 0 do
		driveDown()
		Position.Layer = Position.Layer - 1
	end
end

--
-- Return to the previous mining position and continue
--
function returnToMine(layer, bottom, left)
	-- go back to where we were
	reOrient(Direction.FORWARD)

	while Position.Layer < SavedPosition.Layer do
		driveUp()
		Position.Layer = Position.Layer+1
	end

	if layer ~= 0 then
		driveUp()
		Position.Layer = Position.Layer+1
	end

	moveForward(bottom)
	turnRight()
	moveForward(left)

	if layer ~= 0 then
		driveDown()
	end

	-- reset the position to where we were
	reOrient(SavedPosition.Orientation)

	for key,value in pairs(SavedPosition) do
		Position[key] = value
	end
end

---
--- Dump Cargo
---
function emptyInventory()
	--4:
	for i=1, 15 do
		turtle.select(i)
		turtle.drop()
	end
end

---
--- Main Loop
---

-- Go to the top layer and work down
for i=1, QuarryFrameHeight do
	driveUp()
	Position.Layer = Position.Layer + 1
end

-- clear each layer from the top down
while Position.Layer >= 0 do
	clearLayer()

	if Position.Layer > 0 then
		moveDown()
	end

	Position.Layer = Position.Layer - 1
	Position.Column = 0
	Position.Row = 0
end

-- return to origin and dump cargo
returnToOrigin(0, 0, QuarryFrameWidth)
emptyInventory()

print("Done!")