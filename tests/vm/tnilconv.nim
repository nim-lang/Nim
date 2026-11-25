# bug #26406: T(nil) for pointer-like types in a const context

type C = proc (x: int): int {.closure.}

const a = (proc())(nil)
const b = (proc() {.nimcall.})(nil)
const c = (ptr int)(nil)
const d = (ref int)(nil)
const e = cstring(nil)
const f = pointer(nil)
const g = C(nil)

const _ = (proc())(nil)

static:
  doAssert a == nil
  doAssert b == nil
  doAssert c == nil
  doAssert d == nil
  doAssert e == nil
  doAssert f == nil
  doAssert g == nil
  let x = (proc())(nil)
  doAssert x == nil

doAssert a == nil
doAssert b == nil
doAssert c == nil
doAssert d == nil
doAssert e == nil
doAssert f == nil
doAssert g == nil

# `$cstring(nil)` must fold to "" instead of crashing the compiler
# ("cannot extract string from invalid AST node"); matches the runtime result.
const dollarNilCstr = $cstring(nil)
static:
  doAssert dollarNilCstr == ""
  doAssert $cstring(nil) == ""
doAssert dollarNilCstr == ""
block:
  let x: cstring = nil
  doAssert $x == ""
