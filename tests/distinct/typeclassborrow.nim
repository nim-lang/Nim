import std/tables

type
  Foo = distinct seq[int]
  Bar[N: static[int]] = distinct seq[int]
  Baz = distinct Bar[10]

proc newSeq(s: var Foo, n: Natural) {.borrow.}
proc newSeq(s: var Bar, n: Natural) {.borrow.}
proc newSeq(s: var Baz, n: Natural) {.borrow.}


proc `$`(s: Foo): string {.borrow.}
proc `$`(s: Bar): string {.borrow.}
proc `$`(s: Baz): string {.borrow.}

proc doThing(b: Bar) = discard
proc doThing(b: Baz) {.borrow.}

var
  foo: Foo
  bar: Bar[10]
  baz: Baz

newSeq(foo, 100)
newSeq(bar, bar.N)
newSeq(baz, 10)

bar.doThing()
baz.doThing()

assert $seq[int](foo) == $foo
assert $seq[int](bar) == $bar
assert $seq[int](baz) == $baz

type
  Fine* = distinct string

proc `==`*(x, y: Fine): bool {.borrow.} =
  ## Here is the documentation
  runnableExamples:
    var x = Fine("1234")
    var y = Fine("1234")
    doAssert x == y
  doAssert false


var x = Fine("1234")
var y = Fine("1234")
doAssert x == y

block: # bug #22902
  type
    DistinctTable = distinct Table[int, int]

  proc `[]`(t: DistinctTable; key: int): lent int {.borrow.}
