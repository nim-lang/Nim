discard """
  output: '''
7
collide: unit, thing
collide: unit, thing
collide: thing, unit
collide: thing, thing
Hi derived!
hello
collide: unit, thing | collide: unit, thing | collide: thing, unit | 
do nothing
'''
"""


# tmultim1
type
  Expression = ref object {.inheritable.}
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



# tmultim2
type
  TThing = object {.inheritable.}
  TUnit = object of TThing
    x: int
  TParticle = object of TThing
    a, b: int

method collide(a, b: TThing) {.base, inline.} =
  echo "collide: thing, thing"

method collide(a: TThing, b: TUnit) {.inline.} =
  echo "collide: thing, unit"

method collide(a: TUnit, b: TThing) {.inline.} =
  echo "collide: unit, thing"

proc test(a, b: TThing) {.inline.} =
  collide(a, b)

proc staticCollide(a, b: TThing) {.inline.} =
  procCall collide(a, b)

var
  a: TThing
  b, c: TUnit
collide(b, c) # ambiguous (unit, thing) or (thing, unit)? -> prefer unit, thing!
test(b, c)
collide(a, b)
staticCollide(a, b)



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



# tmultim6
type
  Thing = object {.inheritable.}
  Unit[T] = object of Thing
    x: T
  Particle = object of Thing
    a, b: int

method collide(a, b: Thing) {.base, inline.} =
  quit "to override!"

method collide[T](a: Thing, b: Unit[T]) {.inline.} =
  write stdout, "collide: thing, unit | "

method collide[T](a: Unit[T], b: Thing) {.inline.} =
  write stdout, "collide: unit, thing | "

proc test(a, b: Thing) {.inline.} =
  collide(a, b)

var
  aaa: Thing
  bbb, ccc: Unit[string]
collide(bbb, Thing(ccc))
test(bbb, ccc)
collide(aaa, bbb)
echo ""



# tmethods1
method somethin(obj: RootObj) {.base.} =
  echo "do nothing"

type
  TNode* = object {.inheritable.}
  PNode* = ref TNode

  PNodeFoo* = ref object of TNode

  TSomethingElse = object
  PSomethingElse = ref TSomethingElse

method foo(a: PNode, b: PSomethingElse) {.base.} = discard
method foo(a: PNodeFoo, b: PSomethingElse) = discard

var o: RootObj
o.somethin()
