# Test for --enforceInterfaces flag - this should FAIL

type
  # Define a concept
  Addable = concept x, y
    x + y is typeof(x)

  # This type claims to implement Addable but doesn't!
  Point {.implements: Addable.} = object
    x, y: int

# NOTE: We don't implement the + operator for Point!
# This should cause an error when --enforceInterfaces is enabled

let p1 = Point(x: 1, y: 2)
echo "This shouldn't compile with --enforceInterfaces"
