discard """
  errormsg: "'untyped' is only allowed in templates and macros or magic procs"
  line: 14
"""

# magic procs are allowed with `untyped`
proc declaredInScope2*(x: untyped): bool {.magic: "DefinedInScope", noSideEffect, compileTime.}
proc bar(): bool =
  var x = 1
  declaredInScope2(x)
static: doAssert bar()

# but not non-magic procs
proc fun(x:untyped)=discard
fun(10)
