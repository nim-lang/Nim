discard """
  file: "tvariantstack.nim"
  output: "came here"
"""
#BUG
type
  TAnyKind = enum
    nkInt,
    nkFloat,
    nkString
  PAny = ref TAny
  TAny = object
    case kind: TAnyKind
    of nkInt: intVal: int
    of nkFloat: floatVal: float
    of nkString: strVal: string

  TStack* = object
    list*: seq[TAny]

proc newStack(): TStack =
  result.list = @[]

proc push(Stack: var TStack, item: TAny) =
  var nSeq: seq[TAny] = @[item]
  for i in items(Stack.list):
    nSeq.add(i)
  Stack.list = nSeq

proc pop(Stack: var TStack): TAny =
  result = Stack.list[0]
  Stack.list.delete(0)

var stack = newStack()

var s: TAny
s.kind = nkString
s.strVal = "test"

stack.push(s)

var nr: TAny
nr.kind = nkint
nr.intVal = 78

stack.push(nr)

var t = stack.pop()
echo "came here"



