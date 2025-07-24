discard """
  output: '''
OBJ 1 foo
10
OBJ 1 bar
OBJ 2 foo
5
OBJ 2 bar
'''
"""

type
  # these are the signatures of the virtual procs for each type
  fooProc[T] = proc (o: var T): int {.nimcall.}
  barProc[T] = proc (o: var T) {.nimcall.}

  # an untyped table to store the proc pointers
  # it's also possible to use a strongly typed tuple here
  VTable = array[0..1, pointer]

  TBase {.inheritable.} = object
    vtbl: ptr VTable

  TUserObject1 = object of TBase
    x: int

  TUserObject2 = object of TBase
    y: int

proc foo(o: var TUserObject1): int =
  echo "OBJ 1 foo"
  return 10

proc bar(o: var TUserObject1) =
  echo "OBJ 1 bar"

proc foo(o: var TUserObject2): int =
  echo "OBJ 2 foo"
  return 5

proc bar(o: var TUserObject2) =
  echo "OBJ 2 bar"

proc getVTable(T: typedesc): ptr VTable =
  # pay attention to what's going on here
  # this will initialize the vtable for each type at program start-up
  #
  # fooProc[T](foo) is a type coercion - it looks for a proc named foo
  # matching the signature fooProc[T] (e.g. proc (o: var TUserObject1): int)
  var vtbl {.global.} = [
    cast[pointer](fooProc[T](foo)),
    cast[pointer](barProc[T](bar))
  ]

  return vtbl.addr

proc create(T: typedesc): T =
  result.vtbl = getVTable(T)

proc baseFoo(o: var TBase): int =
  return cast[fooProc[TBase]](o.vtbl[0])(o)

proc baseBar(o: var TBase) =
  cast[barProc[TBase]](o.vtbl[1])(o)

var a = TUserObject1.create
var b = TUserObject2.create

echo a.baseFoo
a.baseBar

echo b.baseFoo
b.baseBar

