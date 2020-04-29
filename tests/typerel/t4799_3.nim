discard """
  targets: "c cpp"
  outputsub: '''ObjectAssignmentDefect'''
  exitcode: "1"
"""

type
  Vehicle = object of RootObj
    tire: int
  Car = object of Vehicle
  Bike = object of Vehicle

proc testVehicle(x: varargs[Vehicle]): string =
  result = ""
  for c in x:
    result.add $c.tire

var v = Vehicle(tire: 3)
var c = Car(tire: 4)
var b = Bike(tire: 2)
echo testVehicle([b, c, v])