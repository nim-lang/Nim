discard """
  cmd: "nim check --newruntime --hints:off $file"
  nimout: '''
tdont_return_unowned_from_owned.nim(36, 10) Error: cannot return an owned pointer as an unowned pointer; use 'owned(Obj)' as the return type
tdont_return_unowned_from_owned.nim(39, 10) Error: cannot return an owned pointer as an unowned pointer; use 'owned(Obj)' as the return type
tdont_return_unowned_from_owned.nim(42, 6) Error: type mismatch: got <Obj>
but expected one of:
proc new[T](a: var ref T; finalizer: proc (x: ref T) {.nimcall.})
  first type mismatch at position: 2
  missing parameter: finalizer
2 other mismatching symbols have been suppressed; compile with --showAllMismatches:on to see them

expression: new(result)
tdont_return_unowned_from_owned.nim(42, 6) Error: illformed AST:
tdont_return_unowned_from_owned.nim(50, 13) Error: assignment produces a dangling ref: the unowned ref lives longer than the owned ref
tdont_return_unowned_from_owned.nim(51, 13) Error: assignment produces a dangling ref: the unowned ref lives longer than the owned ref
tdont_return_unowned_from_owned.nim(55, 10) Error: cannot return an owned pointer as an unowned pointer; use 'owned(RootRef)' as the return type
'''
  errormsg: "cannot return an owned pointer as an unowned pointer; use 'owned(RootRef)' as the return type"
"""









## line 30
# bug #11073
type
  Obj = ref object

proc newObjA(): Obj =
  result = new Obj

proc newObjB(): Obj =
  result = Obj()

proc newObjC(): Obj =
  new(result)

let a = newObjA()
let b = newObjB()
let c = newObjC()

proc testA(result: var (RootRef, RootRef)) =
  let r: owned RootRef = RootRef()
  result[0] = r
  result[1] = RootRef()

proc testB(): RootRef =
  let r: owned RootRef = RootRef()
  result = r
