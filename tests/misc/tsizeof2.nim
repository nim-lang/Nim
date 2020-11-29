discard """
errormsg: "'sizeof' requires '.importc' types to be '.completeStruct'"
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
