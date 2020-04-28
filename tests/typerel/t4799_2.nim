discard """
  targets: "c cpp"
  outputsub: '''ObjectAssignmentDefect'''
  exitcode: "1"
"""

type
  Vehicle[T] = object of RootObj
    tire: T
  Car[T] = object of Vehicle[T]
  Bike[T] = object of Vehicle[T]

proc testVehicle[T](x: varargs[Vehicle[T]]): string =
  result = ""
  for c in x:
    result.add $c.tire

var v = Vehicle[int](tire: 3)
var c = Car[int](tire: 4)
var b = Bike[int](tire: 2)
echo testVehicle([b, c, v])