discard """
  output: '''24
(bar: "bar")
1244
6
abcdefghijklmnopqrstuvwxyz
145 23
3
2'''
"""

import strutils

const fac4 = (var x = 1; for i in 1..4: x *= i; x)

echo fac4

when true:
  proc test(foo: proc (x, y: int): bool) =
    echo foo(5, 5)


  type Foo = object
    bar: string

  proc newfoo(): Foo =
    result.bar = "bar"

  echo($newfoo())


  proc retInt(x, y: int): int =
    if (var yy = 0; yy != 0):
      echo yy
    else:
      echo(try: parseInt("1244") except ValueError: -1)
    result = case x
             of 23: 3
             of 64:
                    case y
                    of 1: 2
                    of 2: 3
                    of 3: 6
                    else: 8
             else: 1

  echo retInt(64, 3)

  proc buildString(): string =
    result = ""
    for x in 'a'..'z':
      result.add(x)

  echo buildString()

#test(
#  proc (x, y: int): bool =
#  if x == 5: return true
#  if x == 2: return false
#  if y == 78: return true
#)

proc q(): int {.discardable.} = 145
proc p(): int =
  q()

proc p2(a: int): int =
  # result enforces a void context:
  if a == 2:
    result = 23
  q()

echo p(), " ", p2(2)

proc semiProblem() =
  if false: echo "aye"; echo "indeed"

semiProblem()


# bug #844

import json
proc parseResponse(): JsonNode =
  result = % { "key1": % { "key2": % "value" } }
  for key, val in result["key1"]:
    var excMsg = key & "("
    if (var n=result["key2"]; n != nil):
      excMsg &= n.str
    raise newException(CatchableError, excMsg)



#bug #992
var se = @[1,2]
let b = (se[1] = 1; 1)


# bug #1161

type
  PFooBase = ref object of RootRef
    field: int

  PFoo[T] = ref object of PFooBase
    field2: T

var testIf =
  if true:
    2
  else:
    3

var testCase =
  case 8
  of 8: 9
  else: 10

var testTry =
  try:
    PFoo[string](field: 3, field2: "asfasf")
  except:
    PFooBase(field: 5)

echo(testTry.field)

# bug #6166

proc quo(op: proc (x: int): bool): int =
  result =
     if op(3):
        2
     else:
        0

echo(
  if true:
     quo do (a: int) -> bool:
        a mod 2 != 0
  else:
     quo do (a: int) -> bool:
        a mod 3 != 0
)

# bug #6980

proc fooBool: bool {.discardable.} =
  true

if true:
  fooBool()
else:
  raise newException(ValueError, "argh")

# bug #5374

proc test1(): int64 {.discardable.} = discard
proc test2(): int {.discardable.} = discard

if true:
  test1()
else:
  test2()
