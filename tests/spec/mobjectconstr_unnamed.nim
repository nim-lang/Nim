type
  Standard* = object
    name: string
    id*: int
    owner*: string

  Color1* = enum
    Red, Blue, Green

  Case1* = object
    name*: string
    id*: int
    color*: Color1
    owner: string


## inplace object construction works
doAssert Standard("Tree", 1, "sky") == Standard(name: "Tree", id: 1, owner: "sky")

proc initStandard*(name: string, id: int, owner: string): Standard =
  Standard(name, id, owner)

## It works in the procs
doAssert initStandard("Tree", 1, "sky") == Standard(name: "Tree", id: 1, owner: "sky")
static: doAssert initStandard("Tree", 1, "sky") == Standard(name: "Tree", id: 1, owner: "sky")

template toStandard*(name: string, id: int, owner: string): Standard =
  Standard(name, id, owner)

## It works in the procs
doAssert toStandard("Tree", 1, "sky") == Standard(name: "Tree", id: 1, owner: "sky")
static: doAssert toStandard("Tree", 1, "sky") == Standard(name: "Tree", id: 1, owner: "sky")

proc initColorRed*(name: string = "red", id: int = 1314, owner: string): Case1 =
  result = Case1(name, id, Red, owner)

doAssert Case1("red", 1314, color: Red, owner: "unknown") == Case1("red", 1314, color: Red, "unknown")
doAssert Case1("red", 1314, Red, owner: "unknown") == Case1("red", 1314, Red, "unknown")
doAssert initColorRed(owner = "unknown") == Case1("red", id: 1314, Red, "unknown")
