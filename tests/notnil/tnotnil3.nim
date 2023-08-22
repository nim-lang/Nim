discard """
  errormsg: "cannot prove 'variable' is not nil"
  line: 31
"""

# bug #584
# Testprogram for 'not nil' check
{.experimental: "notnil".}
const testWithResult = true

type
  A = object
  B = object
  C = object
    a: ref A
    b: ref B


proc testNotNil(c: ref C not nil) =
  discard


when testWithResult:
  proc testNotNilOnResult(): ref C =
    new(result)
    #result.testNotNil() # Here 'not nil' can't be proved


var variable: ref C
new(variable)
variable.testNotNil() # Here 'not nil' is proved

when testWithResult:
  discard testNotNilOnResult()

