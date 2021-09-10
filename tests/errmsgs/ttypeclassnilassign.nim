discard """
cmd: "nim check $options --hints:off $file"
action: "reject"
nimout:'''
ttypeclassnilassign.nim(20, 23) Error: 'PIntFloat' is generic, the concrete type cannot be inferred when initializing as 'nil'.
ttypeclassnilassign.nim(20, 5) Error: invalid type: 'typeof(nil)' for var
ttypeclassnilassign.nim(22, 19) Error: 'MyType' is generic, the concrete type cannot be inferred when initializing as 'nil'.
ttypeclassnilassign.nim(28, 16) Error: 'ProcA' is generic, the concrete type cannot be inferred when initializing as 'nil'.
ttypeclassnilassign.nim(37, 40) Error: 'proc' is generic, the concrete type cannot be inferred when initializing as 'nil'.
'''
"""
block:
  type
    PIntFloat = ptr float or ptr int
    MyType = proc(a: object){.nimcall.}
    AnObject = object
    ProcB = proc(a: AnObject) {.nimcall.}

  var
    test: PIntFloat = nil
    test2: PIntFloat = (ptr float) nil
    foo: MyType = nil
    foo2: MyType = (ProcB) nil

block: # typedesc test
  type ProcA = proc(a: typedesc)
  var
    a: ProcA = nil
    b: ProcA = (proc(a: int){.nimcall.}) nil

block: # used in a proc
  proc new[T](a: var ref T, finalizer: proc (x: ref T) {.nimcall.}) = discard
  var a: ref int
  new(a, nil)

block: # minimized 18204
  proc foo(this: int, callback: proc = nil) = discard
  let sub = 100
  sub.foo()
block:
  type
    FloatInt = float or int
    TypeA[T, Y] = object
  proc foo[T](this: int, callback: ref T = nil) = discard
  proc foo2[T, Y](this: int, callback: ref TypeA[T, Y] = nil) = discard
  foo[int](100, nil)
  foo2[int, float](100)