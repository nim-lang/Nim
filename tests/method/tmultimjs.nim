discard """
  output: '''
7
Hi derived!
hello
'''
  disabled: true
"""


# tmultim1
type
  Expression {.inheritable.} = ref object
  Literal = ref object of Expression
    x: int
  PlusExpr = ref object of Expression
    a, b: Expression

method eval(e: Expression): int {.base.} = quit "to override!"
method eval(e: Literal): int = return e.x
method eval(e: PlusExpr): int = return eval(e.a) + eval(e.b)

proc newLit(x: int): Literal =
  new(result)
  result.x = x

proc newPlus(a, b: Expression): PlusExpr =
  new(result)
  result.a = a
  result.b = b

echo eval(newPlus(newPlus(newLit(1), newLit(2)), newLit(4))) #OUT 7



# tmultim3
import mmultim3

type TBObj* = object of TObj

method test123(a : ref TBObj) =
    echo("Hi derived!")

var aa: ref TBObj
new(aa)
myObj = aa
testMyObj()



# tmultim4
type Test = object of RootObj

method doMethod(a: ref RootObj) {.base, raises: [IoError].} =
  quit "override"

method doMethod(a: ref Test) =
  echo "hello"
  if a == nil:
    raise newException(IoError, "arg")

proc doProc(a: ref Test) =
  echo "hello"

proc newTest(): ref Test =
  new(result)

var s:ref Test = newTest()

#doesn't work
for z in 1..4:
  s.doMethod()
  break
