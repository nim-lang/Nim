discard """
  matrix: "--mm:refc; --mm:orc"
"""

# bug #26770: a default argument whose expression declares a local
# (`v = (let res = 1; res)`, typically produced by a template) made
# lambdalifting treat the declaration's symbol as an upvalue when the
# call happened inside another proc: `internal error: environment
# misses: res`. The same call at top level worked.

proc f(v = (let res = 1; res)): int = v

template mk(): int =
  let res = 1
  res

proc g(v = mk()): int = v

proc mkProc(): int = (let res = 1; res)
proc h(v = mkProc()): int = v

proc main() =
  doAssert f() == 1 # direct expression form
  doAssert g() == 1 # template form
  doAssert h() == 1 # proc default (control; always worked)
  doAssert f((let res = 1; res)) == 1 # explicit argument
  proc deep() =
    doAssert f() == 1 # call from a nested proc
  deep()

main()

doAssert f() == 1 # top level call (control; always worked)

# surrounding captures must still take the upvalue path
proc captures() =
  var y = 1
  proc add() = y += 1
  add()
  doAssert y == 2

captures()
