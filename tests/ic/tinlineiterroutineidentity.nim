discard """
  description: "Inline iterator expansion preserves routine identity and independent closure state"
"""

#? metamorphic

#!FILE helper.nim
type
  Plain* = proc(): int {.nimcall.}
  Closure* = proc(): int {.closure.}
  Factory* = proc(): Closure {.nimcall.}
iterator plain*(): Plain =
  proc value(): int =
    var calls {.global.}: int
    inc calls
    calls
  yield value
iterator closures*(): Closure =
  proc value(): int {.closure.} = 42
  yield value
iterator capturing*(): Closure =
  var count = 0
  proc value(): int =
    inc count
    count
  yield value
  yield value

iterator factories*(): Factory =
  proc factory(): Closure =
    var count = 0
    result = proc(): int =
      inc count
      count
  yield factory

iterator values*[T](value: T): auto =
  var held = value
  proc read(): T = held
  yield read

#!FILE other.nim
import helper
proc fromOther*(): Plain =
  for f in plain(): result = f
proc closureFromOther*(): Closure =
  for f in closures(): result = f

proc captureFromOther*(): Closure =
  for f in capturing(): result = f
proc factoryFromOther*(): Factory =
  for f in factories(): result = f

proc numberFromOther*(): proc(): int =
  for f in values(456): result = f

#!FILE main.nim
import helper, other
proc first(): Plain =
  for f in plain(): result = f
proc second(): Plain =
  for f in plain(): result = f
proc closureFirst(): Closure =
  for f in closures(): result = f
proc saved(): seq[Closure] =
  for f in capturing(): result.add f
let x = saved()
let y = saved()
echo x[0] == x[1], " ", x[0] == y[0]
echo x[0](), " ", x[1](), " ", y[0]()
let z = captureFromOther()
echo rawProc(x[0]) == rawProc(z), " ", z()
var factory: Factory
for f in factories(): factory = f
echo factory == factoryFromOther()
let inner = factory()
echo inner(), " ", inner()
var number: proc(): int
var word: proc(): string
for f in values(123): number = f
for f in values("abc"): word = f
let otherNumber = numberFromOther()
echo number(), " ", word(), " ", otherNumber()
echo rawProc(number) == rawProc(otherNumber)
let a = first()
let b = second()
let c = fromOther()
echo a == b, " ", a == c
echo a(), " ", b(), " ", c()
echo closureFirst() == closureFromOther()
echo rawProc(closureFirst()) == rawProc(closureFromOther())
#!STEP expect: true false\n1 2 1\ntrue 1\ntrue\n1 2\n123 abc 456\ntrue\ntrue true\n1 2 3\nfalse\ntrue
#!STEP
#!STEP noop
