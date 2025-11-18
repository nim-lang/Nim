# Test invalid pragma syntax

type
  # Missing the concept name - should error
  TestType {.implements.} = object
    x: int

echo "done"
