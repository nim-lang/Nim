# regression from #24184, see #24191

const a: seq[string] = @[]

proc foo(x = a) =
  doAssert x is seq[string]
  doAssert x == @[]

proc bar(x: static seq[string] = a) =
  doAssert x is seq[string]
  doAssert x == @[]
  const y = x
  doAssert y == x

# issue #22793
proc baz(x: static seq[string] = @[]) =
  doAssert x is seq[string]
  doAssert x == @[]
  const y = x
  doAssert y == x

import macros

macro resem(x: typed) =
  expectKind x, nnkSym
  result = getImpl(x)

foo()
bar()
baz()
block:
  resem(foo) # Error: cannot infer the type of parameter 'x'
  resem(bar)
  resem(baz)
  foo()
  bar()
  baz()
