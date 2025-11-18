# Simple test to see if pragma is recognized

type
  TestType {.implements: SomeNonExistentConcept.} = object
    x: int

echo "If this compiles, the pragma wasn't validated"
