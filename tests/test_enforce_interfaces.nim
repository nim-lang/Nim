# Test for --enforceInterfaces flag and {.implements.} pragma

type
  # Define a simple concept
  Addable = concept x, y
    x + y is typeof(x)

  # Define a concept with multiple requirements
  Printable = concept x
    $x is string

  # This type DOES implement Addable
  Vector {.implements: Addable.} = object
    x, y: float

# Implementation of + operator
proc `+`(a, b: Vector): Vector =
  Vector(x: a.x + b.x, y: a.y + b.y)

# Test that it compiles with the concept satisfied
let v1 = Vector(x: 1.0, y: 2.0)
let v2 = Vector(x: 3.0, y: 4.0)
let v3 = v1 + v2

echo "Test passed: Vector implements Addable correctly"
