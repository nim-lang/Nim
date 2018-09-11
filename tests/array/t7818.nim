discard """
  output: "OK"
"""

# bug #7818
# this is not a macro bug, but array construction bug
# I use macro to avoid object slicing
# see #7712 and #7637
import macros

type
  Vehicle[T] = object of RootObj
    tire: T
  Car[T] = object of Vehicle[T]
  Bike[T] = object of Vehicle[T]

macro peek(n: typed): untyped =
  let val = getTypeImpl(n).treeRepr
  newLit(val)

block test_t7818:
  var v = Vehicle[int](tire: 3)
  var c = Car[int](tire: 4)
  var b = Bike[int](tire: 2)

  let y = peek([c, b, v])
  let z = peek([v, c, b])
  doAssert(y == z)
  
block test_t7906_1:
  proc init(x: typedesc, y: int): ref x =
    result = new(ref x)
    result.tire = y
  
  var v = init(Vehicle[int], 3)
  var c = init(Car[int], 4)
  var b = init(Bike[int], 2)

  let y = peek([c, b, v])
  let z = peek([v, c, b])
  doAssert(y == z)
  
block test_t7906_2:
  var v = Vehicle[int](tire: 3)
  var c = Car[int](tire: 4)
  var b = Bike[int](tire: 2)

  let y = peek([c.addr, b.addr, v.addr])
  let z = peek([v.addr, c.addr, b.addr])
  doAssert(y == z)

block test_t7906_3:
  type
    Animal[T] = object of RootObj
      hair: T
    Mammal[T] = object of Animal[T]
    Monkey[T] = object of Mammal[T]

  var v = Animal[int](hair: 3)
  var c = Mammal[int](hair: 4)
  var b = Monkey[int](hair: 2)

  let z = peek([c.addr, b.addr, v.addr])
  let y = peek([v.addr, c.addr, b.addr])
  doAssert(y == z)
  
type
  Fruit[T] = ref object of RootObj
    color: T
  Apple[T] = ref object of Fruit[T]
  Banana[T] = ref object of Fruit[T]
    
proc testArray[T](x: array[3, Fruit[T]]): string =
  result = ""
  for c in x:
    result.add $c.color

proc testOpenArray[T](x: openArray[Fruit[T]]): string =
  result = ""
  for c in x:
    result.add $c.color
    
block test_t7906_4:
  var v = Fruit[int](color: 3)
  var c = Apple[int](color: 4)
  var b = Banana[int](color: 2)

  let y = peek([c, b, v])
  let z = peek([v, c, b])
  doAssert(y == z)
  
block test_t7906_5:
  var a = Fruit[int](color: 1)
  var b = Apple[int](color: 2)
  var c = Banana[int](color: 3)

  doAssert(testArray([a, b, c]) == "123")
  doAssert(testArray([b, c, a]) == "231")

  doAssert(testOpenArray([a, b, c]) == "123")
  doAssert(testOpenArray([b, c, a]) == "231")

  doAssert(testOpenArray(@[a, b, c]) == "123")
  doAssert(testOpenArray(@[b, c, a]) == "231")

proc testArray[T](x: array[3, ptr Vehicle[T]]): string =
  result = ""
  for c in x:
    result.add $c.tire

proc testOpenArray[T](x: openArray[ptr Vehicle[T]]): string =
  result = ""
  for c in x:
    result.add $c.tire

block test_t7906_6:
  var u = Vehicle[int](tire: 1)
  var v = Bike[int](tire: 2)
  var w = Car[int](tire: 3)
  
  doAssert(testArray([u.addr, v.addr, w.addr]) == "123")
  doAssert(testArray([w.addr, u.addr, v.addr]) == "312")
  
  doAssert(testOpenArray([u.addr, v.addr, w.addr]) == "123")
  doAssert(testOpenArray([w.addr, u.addr, v.addr]) == "312")
  
  doAssert(testOpenArray(@[u.addr, v.addr, w.addr]) == "123")
  doAssert(testOpenArray(@[w.addr, u.addr, v.addr]) == "312")
  
echo "OK"


