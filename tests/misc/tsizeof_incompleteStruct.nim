discard """
errormsg: "'sizeof' cannot be used with '.incompleteStruct' types"
line: 10
"""

type
  MyStruct {.incompleteStruct.} = object
    field: int

const i = sizeof(MyStruct)

echo i
