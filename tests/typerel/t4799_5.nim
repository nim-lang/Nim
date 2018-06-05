discard """
errormsg: "type mismatch: got <Bike>"
nimout: '''t4799_5.nim(23, 18) Error: type mismatch: got <Bike>
but expected one of:
proc testVehicle(x: varargs[Vehicle]): string

expression: testVehicle b'''
"""

type
  Vehicle = ptr object of RootObj
    tire: int
  Car = object of Vehicle
  Bike = object of Vehicle

proc testVehicle(x: varargs[Vehicle]): string =
  result = ""
  for c in x:
    result.add $c.tire

var c = Car(tire: 4)
var b = Bike(tire: 2)
echo testVehicle b, c