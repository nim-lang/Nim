discard """
  output: '''success'''
"""

# bug #6682
{.experimental: "notnil".}

type
    Fields = enum
        A=1, B, C

    Obj = object
        fld: array[Fields, int]

    AsGeneric[T] = array[Fields, T]
    Obj2[T] = object
      fld: AsGeneric[T]

var a: Obj # this works

var arr: array[Fields, int]

var b = Obj() # this doesn't (also doesn't works with additional fields)

var z = Obj2[int]()

echo "success"

# bug #6555

import tables

type
  TaskOrNil = ref object
  Task = TaskOrNil not nil

let table = newTable[string, Task]()
table.del("task")

# bug #6121

import json

type

  foo = object
    thing: ptr int not nil

  CTS = ref object
    subs_by_sid: Table[int, foo]


proc parse(cts: CTS, jn: JsonNode) =
  var y = jn.getInt(4523)
  let ces = foo(
    thing: addr y
  )

  cts.subs_by_sid[0] = ces


# bug #6489

proc p(x: proc(){.closure.} not nil) = discard
p(proc(){.closure.} = discard)

# bug #6490

proc p2(a: proc()) =
    if a.isNil:
        raise newException(ValueError, "a is nil")
    else:
        let b: proc() not nil = a

p2(writeStackTrace)
