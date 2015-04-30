type T = object
  x: int
  s: string

var obj: T
var fieldAddr = addr(obj.x)
var objAddr = addr(obj)

# Integer tests
var field = fieldAddr[]
doAssert field == 0

var objDeref = objAddr[]
doAssert objDeref.x == 0

# Change value
obj.x = 42

doAssert field == 0
doAssert objDeref.x == 0

field = fieldAddr[]
objDeref = objAddr[]

doAssert field == 42
doAssert objDeref.x == 42

# String tests
obj.s = "lorem ipsum dolor sit amet"
var indexAddr = addr(obj.s[2])

doAssert indexAddr[] == '4'

indexAddr[] = 'd'

doAssert indexAddr[] == 'd'
