discard """
errormsg: "type mismatch: got <Bike[system.int]>"
nimout: '''t4799_4.nim(23, 18) Error: type mismatch: got <Bike[system.int]>
but expected one of:
proc testVehicle[T](x: varargs[Vehicle[T]]): string

expression: testVehicle b'''
"""

type
  Vehicle[T] = ptr object of RootObj
    tire: T
  Car[T] = object of Vehicle[T]
  Bike[T] = object of Vehicle[T]

proc testVehicle[T](x: varargs[Vehicle[T]]): string =
  result = ""
  for c in x:
    result.add $c.tire

var c = Car[int](tire: 4)
var b = Bike[int](tire: 2)
echo testVehicle b, c