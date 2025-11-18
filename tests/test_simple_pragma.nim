# Test to see if pragma is processed

type
  # This should error because NonExist doesn't exist
  TestType {.implements: NonExist.} = object
    x: int

echo "done"
