discard """
errormsg: "cannot evaluate 'sizeof' because its type is not defined completely"
line: 9
"""

type
  MyStruct {.importc: "MyStruct".} = object

const i = sizeof(MyStruct)

echo i

# bug #9868
proc foo(a: SomeInteger): array[sizeof(a), byte] =
  discard

discard foo(1)
