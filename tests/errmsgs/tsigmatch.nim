discard """
  cmd: "nim check --showAllMismatches:on --hints:off $file"
  nimout: '''
tsigmatch.nim(111, 4) Error: type mismatch: got <A, string>
but expected one of:
proc f(a: A)
  first type mismatch at position: 2
  extra argument given
proc f(b: B)
  first type mismatch at position: 1
  required type for b: B
  but expression 'A()' is of type: A

expression: f(A(), "extra")
tsigmatch.nim(125, 6) Error: type mismatch: got <(string, proc (){.gcsafe, locks: 0.})>
but expected one of:
proc foo(x: (string, proc ()))
  first type mismatch at position: 1
  required type for x: (string, proc (){.closure.})
  but expression '("foobar", proc () = echo(["Hello!"]))' is of type: (string, proc (){.gcsafe, locks: 0.})

expression: foo(("foobar", proc () = echo(["Hello!"])))
tsigmatch.nim(132, 11) Error: type mismatch: got <proc (s: string): string{.noSideEffect, gcsafe, locks: 0.}>
but expected one of:
proc foo[T, S](op: proc (x: T): S {.cdecl.}): auto
  first type mismatch at position: 1
  required type for op: proc (x: T): S{.cdecl.}
  but expression 'fun' is of type: proc (s: string): string{.noSideEffect, gcsafe, locks: 0.}
proc foo[T, S](op: proc (x: T): S {.safecall.}): auto
  first type mismatch at position: 1
  required type for op: proc (x: T): S{.safecall.}
  but expression 'fun' is of type: proc (s: string): string{.noSideEffect, gcsafe, locks: 0.}

expression: foo(fun)
tsigmatch.nim(143, 13) Error: type mismatch: got <array[0..0, proc (x: int){.gcsafe, locks: 0.}]>
but expected one of:
proc takesFuncs(fs: openArray[proc (x: int) {.gcsafe, locks: 0.}])
  first type mismatch at position: 1
  required type for fs: openArray[proc (x: int){.closure, gcsafe, locks: 0.}]
  but expression '[proc (x: int) {.gcsafe, locks: 0.} = echo [x]]' is of type: array[0..0, proc (x: int){.gcsafe, locks: 0.}]

expression: takesFuncs([proc (x: int) {.gcsafe, locks: 0.} = echo [x]])
tsigmatch.nim(149, 4) Error: type mismatch: got <int literal(10), a0: int literal(5), string>
but expected one of:
proc f(a0: uint8; b: string)
  first type mismatch at position: 2
  named param already provided: a0

expression: f(10, a0 = 5, "")
tsigmatch.nim(156, 4) Error: type mismatch: got <string, string, string, string, string, float64, string>
but expected one of:
proc f(a1: int)
  first type mismatch at position: 1
  required type for a1: int
  but expression '"asdf"' is of type: string
proc f(a1: string; a2: varargs[string]; a3: float; a4: var string)
  first type mismatch at position: 7
  required type for a4: var string
  but expression '"bad"' is immutable, not 'var'

expression: f("asdf", "1", "2", "3", "4", 2.3, "bad")
tsigmatch.nim(164, 4) Error: type mismatch: got <string, a0: int literal(12)>
but expected one of:
proc f(x: string; a0: string)
  first type mismatch at position: 2
  required type for a0: string
  but expression 'a0 = 12' is of type: int literal(12)
proc f(x: string; a0: var int)
  first type mismatch at position: 2
  required type for a0: var int
  but expression 'a0 = 12' is immutable, not 'var'

expression: f(foo, a0 = 12)
tsigmatch.nim(171, 7) Error: type mismatch: got <Mystring, string>
but expected one of:
proc fun1(a1: MyInt; a2: Mystring)
  first type mismatch at position: 1
  required type for a1: MyInt
  but expression 'default(Mystring)' is of type: Mystring
proc fun1(a1: float; a2: Mystring)
  first type mismatch at position: 1
  required type for a1: float
  but expression 'default(Mystring)' is of type: Mystring

expression: fun1(default(Mystring), "asdf")
'''
  errormsg: "type mismatch"
"""



#[
see also: tests/errmsgs/tdeclaredlocs.nim
]#





## line 100
when true:
  # bug #11061 Type mismatch error "first type mismatch at" points to wrong argument/position
  # Note: the error msg now gives correct position for mismatched argument
  type
    A = object of RootObj
    B = object of A
block:
  proc f(b: B) = discard
  proc f(a: A) = discard

  f(A(), "extra")
#[
this one is similar but error msg was even more misleading, since the user
would think float != float64 where in fact the issue is another param:
first type mismatch at position: 1; required type: float; but expression 'x = 1.2' is of type: float64
  proc f(x: string, a0 = 0, a1 = 0, a2 = 0) = discard
  proc f(x: float, a0 = 0, a1 = 0, a2 = 0) = discard
  f(x = float(1.2), a0 = 0, a0 = 0)
]#

block:
  # bug #7808 Passing tuple with proc leads to confusing errors
  # Note: the error message now shows `closure` which helps debugging the issue
  proc foo(x: (string, proc ())) = x[1]()
  foo(("foobar", proc () = echo("Hello!")))

block:
  # bug #8305 type mismatch error drops crucial pragma info when there's only 1 argument
  proc fun(s: string): string {.  .} = discard
  proc foo[T, S](op: proc (x: T): S {. cdecl .}): auto = 1
  proc foo[T, S](op: proc (x: T): S {. safecall .}): auto = 1
  echo foo(fun)

block:
  # bug #10285 Function signature don't match when inside seq/array/openArray
  # Note: the error message now shows `closure` which helps debugging the issue
  # out why it doesn't match
  proc takesFunc(f: proc (x: int) {.gcsafe, locks: 0.}) =
    echo "takes single Func"
  proc takesFuncs(fs: openArray[proc (x: int) {.gcsafe, locks: 0.}]) =
    echo "takes multiple Func"
  takesFunc(proc (x: int) {.gcsafe, locks: 0.} = echo x)         # works
  takesFuncs([proc (x: int) {.gcsafe, locks: 0.} = echo x])      # fails

block:
  # bug https://github.com/nim-lang/Nim/issues/11061#issuecomment-508970465
  # better fix for removal of `errCannotBindXTwice` due to #3836
  proc f(a0: uint8, b: string) = discard
  f(10, a0 = 5, "")

block:
  # bug: https://github.com/nim-lang/Nim/issues/11061#issuecomment-508969796
  # sigmatch gets confused with param/arg position after varargs
  proc f(a1: int) = discard
  proc f(a1: string, a2: varargs[string], a3: float, a4: var string) = discard
  f("asdf", "1", "2", "3", "4", 2.3, "bad")

block:
  # bug: https://github.com/nim-lang/Nim/issues/11061#issuecomment-508970046
  # err msg incorrectly said something is immutable
  proc f(x: string, a0: var int) = discard
  proc f(x: string, a0: string) = discard
  var foo = ""
  f(foo, a0 = 12)

when true:
  type Mystring = string
  type MyInt = int
  proc fun1(a1: MyInt, a2: Mystring) = discard
  proc fun1(a1: float, a2: Mystring) = discard
  fun1(Mystring.default, "asdf")

