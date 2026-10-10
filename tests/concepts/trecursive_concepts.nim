discard """
action: "run"
output: '''
int is Primitive: true
Handle is Primitive: true
SpecialHandle is Primitive: true
FileDescriptor is Primitive: true
float is Primitive: false
string is Primitive: false
char is PrimitiveBase: true
ptr int is PrimitiveBase: true
'''
"""

# Test recursive concepts with cycle detection
# This tests concepts that reference themselves via distinctBase

import std/typetraits

block: # Basic recursive concept with distinctBase
  type
    PrimitiveBase = SomeInteger | bool | char | ptr | pointer

    # Recursive concept: matches PrimitiveBase or any distinct type whose base is Primitive
    Primitive = concept x
      x is PrimitiveBase or distinctBase(x) is Primitive

    # Real-world example: handle types that wrap integers
    Handle = distinct int
    SpecialHandle = distinct Handle
    FileDescriptor = distinct SpecialHandle

  # Direct base types
  echo "int is Primitive: ", int is Primitive

  # Single-level distinct (like a simple handle type)
  echo "Handle is Primitive: ", Handle is Primitive

  # Two-level distinct
  echo "SpecialHandle is Primitive: ", SpecialHandle is Primitive

  # Three-level distinct
  echo "FileDescriptor is Primitive: ", FileDescriptor is Primitive

  # Non-primitive types should NOT match
  echo "float is Primitive: ", float is Primitive
  echo "string is Primitive: ", string is Primitive

block: # Ensure base type matching still works
  type
    PrimitiveBase = SomeInteger | bool | char | ptr | pointer

  echo "char is PrimitiveBase: ", char is PrimitiveBase
  echo "ptr int is PrimitiveBase: ", (ptr int) is PrimitiveBase

block: # Test that cycle detection doesn't break normal concept matching
  type
    Addable = concept x, y
      x + y is typeof(x)

  doAssert int is Addable
  doAssert float is Addable

block: # Test non-matching recursive case
  type
    IntegerBase = SomeInteger

    IntegerLike = concept x
      x is IntegerBase or distinctBase(x) is IntegerLike

    Percentage = distinct float  # float base, not integer

  doAssert int is IntegerLike
  doAssert not(float is IntegerLike)
  doAssert not(Percentage is IntegerLike)  # float base doesn't match

block: # Test deep distinct chains (5+ levels) - e.g., layered ID types
  type
    IdBase = SomeInteger

    IdLike = concept x
      x is IdBase or distinctBase(x) is IdLike

    EntityId = distinct int
    UserId = distinct EntityId
    AdminId = distinct UserId
    SuperAdminId = distinct AdminId
    RootId = distinct SuperAdminId

  doAssert int is IdLike
  doAssert EntityId is IdLike
  doAssert UserId is IdLike
  doAssert AdminId is IdLike
  doAssert SuperAdminId is IdLike
  doAssert RootId is IdLike
  doAssert not(float is IdLike)

block: # Test 3-way mutual recursion (co-dependent concepts)
  # This tests that cycle detection properly handles A -> B -> C -> A cycles
  type
    Serializable = concept
      proc serialize(x: Self): Bytes

    Bytes = concept
      proc compress(x: Self): Compressed

    Compressed = concept
      proc decompress(x: Self): Serializable

    Data = object
      value: int

  proc serialize(x: Data): Data = x
  proc compress(x: Data): Data = x
  proc decompress(x: Data): Data = x

  # Data should satisfy all three mutually recursive concepts
  doAssert Data is Serializable
  doAssert Data is Bytes
  doAssert Data is Compressed

block: # Test concept with method returning same type
  type
    Cloneable = concept
      proc clone(x: Self): Self

    Document = object
      content: string

  proc clone(x: Document): Document = x

  doAssert Document is Cloneable
