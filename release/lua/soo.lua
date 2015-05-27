--[[
  very Simple Object-Oriented lua script

  create class with initial table {properties & methods}
  **subclass can not change superclass definition of {properties & methods}

  properties of returned lua table :
    isInstance: true or false
    class: class of this instance, **for instance only
    super: superclass of this class/instance

  methods of returned lua table :
    new(initialParameters): create new instance only, can be ignored with {} directly
    toString(): do not be implemented yet, but recommend to do that
    extended(fields): create subclass of this class, **for class only

]]
function class( initial )
  local cls = initial or {}

  --[[
    create new instance
  ]]
  function cls:new(fields)
    if self.isInstance then
      error("Instance can not be instantiated again, using <class> please")
    end

    local o = fields or {}
    setmetatable( o, self ) --associate o with self

    self.__index = self
    o.class=self --==getmetatable(o)

    self.__tostring = function ( tb )
        return tb:toString()
    end
    o.isInstance=true

    --print(o, "new instance of ", self)

    return o
  end

  --[[
    create subclass
  ]]
  function cls:extended(fields)
    if self.isInstance then
      error("Instance can not be extended , using <class> please")
    end
    local sub = self:new(fields)
    sub.__index = self
    sub.super = self

    getmetatable(sub).__call = function (tb, ... )
        return tb:new(...)
    end
    getmetatable(sub).__tostring = function ( tb )
        return tb:toString()
    end

    getmetatable(self).__newindex = function ( tb, k, v )
         if k == '__index' or k == '__newindex' or k=='__tostring' or k=='__call' then
           rawset(tb,k,v)
           return
         end
         error("can not change class properties/methods definition: " .. k)
    end


    sub.isInstance = false
    return sub
  end

  function cls:toString()
    error("toString() is NOT implemented")
  end

  cls.isInstance = false

  setmetatable(cls, {
      __call = function (tb, ... )
        return tb:new(...)
      end,
      __tostring = function ( tb )
        return tb:toString()
      end,
      __newindex = function ( tb, k, v )
         if k == '__index' or k == '__newindex' or k=='__tostring' or k=='__call' then
           rawset(tb,k,v)
           return
         end
         error("can not change class properties/methods definition:" .. k)
      end
  })

  return cls
end


--[[--------test--------------

local Shape = class{
  name = "Shape",
  desc = "Shape desc",
  lengthOfEdge = 1,
  edges = 1,
  circumference = function ()
      print("Method(circumference) NOT implement")
  end
}
--genernal method!
function Shape:toString()
  return self.name
end
--getmetatable(Shape).__tostring = function ( )
--  return Shape.name --not effective for subclass!
--end

local s = Shape{name = "triangle", edges = 3}
s:circumference()

local Square = Shape:extended{ name = "Square", edges = 4 }
--override superclass method
function Square:circumference()
  print( self.name .. " > [Square]circumference=" .. (self.lengthOfEdge * self.edges))
end

--Square:circumference()

local sq1 = Square{name = "sq1", lengthOfEdge = 100}
local sq2 = Square{name = "sq2", lengthOfEdge = 200}
print("tostring() test for \n superclass,subclass,instance, class of instance, superclass of class :\n",Shape, Square, sq1, sq2.class, Square.super)

sq1:circumference()
sq2:circumference()

sq1.super:circumference()

print(Square.name, Square.isInstance, sq1, sq1.isInstance,sq2.super.name,sq2.super.isInstance)

Square.super.name="changed super name"
print(Shape, Square.desc)

local SpecialSquare = Square:extended{ name = "SpecialSquare", createTime = false }
local ssq = SpecialSquare{name="ssq1", createTime=os.time()}

print(SpecialSquare.super, SpecialSquare, ssq)

function SpecialSquare:newMethod( str )
  print("newMethod>", str)
end

ssq:newMethod("test")
function ssq:m( )

end


--uncomment the following line to test error operation

--local errorExtended = (sq2:extended{ name = "new class extended from instance"})
--local errorNewInstance = (sq1:new{ name = "new instance from instance"})

--ERROR: can not change class properties/methods definition
--SpecialSquare.super.newProperty=true
--SpecialSquare.super.newMethod = function (  )
--end
--sq1.super.newProperty=true
--Square.super.newMethod = function (  )
--end

--]]
