discard """
  cmd: "nim check $file"
"""

var x = 3
template foo: untyped {.alias.} = x
var y = 4
template foo: untyped {.alias.} = y #[tt.Error
^ redefinition of 'foo'; previous declaration here: taliastemplateerrors.nim(6, 10)]#
template foo: untyped {.alias, redefine.} = y
doAssert foo == y
proc foo(x: int): int = x + 1 #[tt.Error
     ^ redefinition of 'foo'; previous declaration here: taliastemplateerrors.nim(10, 10)]#

template minus: untyped {.alias.} = `-`
discard minus() #[tt.Error
             ^ type mismatch: got <>]#
block:
  # cannot use if overloaded
  template minus(a, b, c): untyped = a - b - c
  doAssert minus(3, 5, 8) == -10
  discard minus(1) #[tt.Error
               ^ type mismatch: got <int literal(1)>]#
