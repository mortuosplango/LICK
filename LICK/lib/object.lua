-- OBJECT.lua
-- object oriented livecoding library
_internal_object_table = {}

-- hump for classing
local Class = require "LICK/lib/hump/.class"
local hlpr = require "LICK/lib/hlpr"
require "LICK/lib/loveosc"


--[[
	OBJECT
--]]
-- @Object: base class
Object = Class(function(self)
	-- TODO: Object base code
	table.insert(_internal_object_table, self)
end)

function Object:update(dt)
	-- TODO: insert typical update
	-- print("updated")
end

--[[
	SCOBJECT
--]]

-- @SCObject: bass class for supercollider communication
SCObject = Class(function(self)
	Object.construct(self)
end)
SCObject:inherit(Object)


--[[
	SCSERVER
--]]

SCServer = Class(function(self)
                    SCObject.construct(self)
                    SCServer.nodeID = 1000
                 end)
SCServer:inherit(SCObject)

function SCServer:getNodeID()
   self.nodeID = (self.nodeID + 1) % 67108863
   return self.nodeID
end

function SCServer:send(var)
   osc.client:send(var)
end

function SCServer:freeAll()
   self:send{'/g_freeAll', 'i', 0}
   self:send{'/clearSched'}
end

function SCServer:loadSynthDef(path)
   self.send{'/d_load', 's', path}
end



--[[
	SCNODE
--]]

SCNode = Class(
   function(self, nodeid, addAction, addTargetID)
      SCObject.construct(self)
      self.server = server
      self.nodeid = nodeid or self.server:getNodeID()
      self.addAction = addAction or 1
      self.addTargetID = addTargetID or 0
   end)
SCNode:inherit(SCObject)


-- #set a control
function SCNode:set(settings)
   local var = {
      --"#bundle",
      --os.time(),
      --{
      "/n_set",
      "i",
      self.nodeid
      --}
   }
   for param, value in pairs(settings) do
      for p,i in ipairs{'s', param, 'f', value} do
         table.insert(var, i)
      end
   end
   self.server:send(var)
   --print("OUTGOING OSC MESSAGE")
end

--#frees the node on the supercollider server
function SCNode:free()
   local var = {
      "#bundle",
      os.time()+0.8,
      {
         "/n_free",
         "i",
         self.nodeid,
         "i",
         0,
      }
   }
   self.server:send(var)
   --print("OUTGOING OSC MESSAGE")
end

--[[
	SCGROUP
--]]

-- @SCGroup: supercollider synth group class
SCGroup = Class(function(self, addAction, addTargetID)
	SCNode.construct(self, nodeid, addAction, addTargetID)
	local var = {
       --"#bundle",
       --os.time(),
       --{
       "/g_new",
       "i",
       self.nodeid,
       "i",
       self.addAction,
       "i",
       self.addTargetID,
       --}
	}
	self.server:send(var)
end)
SCGroup:inherit(SCNode)

function SCGroup:freeAll()
   self.server:send{"/g_freeAll",
                    "i",
                    self.nodeid}
end


--[[
	SCSYNTH
--]]


-- @SCSynth: supercollider synthesizer class
SCSynth = Class(function(self, nodename, freq, settings, addAction, addTargetID)
	SCNode.construct(self, nodeid, addAction, addTargetID)
	self.nodename = nodename or "default"
	self.freq = freq or 440
    self.settings = settings
end)
SCSynth:inherit(SCNode)


--#sends an OSC message to the supercollider to start the synth
function SCSynth:play()
	local var = {
		--"#bundle",
		--os.time(),
		--{
	            "/s_new",
		    "s",
		    self.nodename,
		    "i",
		    self.nodeid,
		    "i",
		    self.addAction,
		    "i",
		    self.addTargetID,
		    "s",
		    "freq",
		    "f",
		    self.freq
		--}
	}
    if self.settings then
       for param, value in pairs(self.settings) do
          for p,i in ipairs{'s', param, 'f', value} do
             table.insert(var, i)
          end
       end
    end
	self.server:send(var)
	--print("OUTGOING OSC MESSAGE")
end


--[[
	DRAWABLE
--]]
-- @Drawable: base class for all drawable stuff
Drawable = Class(function(self, x, y, color)
	self.color = color or hlpr.color("white",255)
	-- call constructor of Object class
	Object.construct(self)

	self.position = Vector(x,y)
	self.pos = self.position
	self.x = self.position.x
	self.y = self.position.y
end)
Drawable:inherit(Object)

-- #can be called via wrapX(max) or wrapX(min,max)
function Drawable:wrapX(min, max)
	if min and max then
		self:wrap("x", min, max)
	elseif min and not max then 
		self:wrap("x", 0, min)
	end
end

-- #can be called via wrapY(max) or wrapY(min,max)
function Drawable:wrapY(min, max)
	if min and max then
		self:wrap("y", min, max)
	elseif min and not max then 
		self:wrap("y", 0, min)
	end
end

-- #internal wrapper
function Drawable:wrap(str, min, max)
	if str == "x" then
		self.position.x = hlpr.wrap(self.position.x, min, max)
	elseif str == "y" then
		self.position.y = hlpr.wrap(self.position.y, min, max)
	end
end

-- #supercollider style 'set'
function Drawable:set(str, val)

	if str == "x" then 
		self.position.x = val or self.position.x
	elseif str == "y" then
		self.position.y = val or self.position.y
	end
	-- TODO: add lots and lots and lots
end

-- #not yet implemented
function Drawable:draw()
	-- TODO: abstract draw code...
end




--[[
	CIRCLE
--]]
-- @Circle: drawable circle
Circle = Class(function(self, x, y, r, s, color)
	self.r = r or 10
	self.s = s or 16
	-- call constructor of Drawable
	Drawable.construct(self,x,y,color)
end)
Circle:inherit(Drawable)

-- #draw the circle
function Circle:draw(style)
	if style ~= "fill" and style ~= "line" then
		style = "line"
	end
	love.graphics.setColor(unpack(self.color))
	love.graphics.circle(style, self.position.x, self.position.y, self.r, self.s)
end



--[[
	LINE
--]]
-- @Line: draw a line
Line = Class(function(self, x, y, tx, ty)
	self.tx = tx or 0
	self.ty = ty or 0
	-- call constructor of Drawable
	Drawable.construct()
	
end)
Line:inherit(Object)


-- EXAMPLE:
-- (put in love.load):
-- 	coco = Circle(300,300)
-- (put in love.update):
-- 	coco:set("x", 30)
-- (put in love.draw): 	
-- 	coco:draw("fill")

