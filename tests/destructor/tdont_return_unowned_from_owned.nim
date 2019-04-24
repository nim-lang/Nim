discard """
  cmd: "nim check --newruntime --hints:off $file"
  nimout: '''tdont_return_unowned_from_owned.nim(24, 10) Error: cannot return an owned pointer as an unowned pointer; use 'owned(Obj)' as the return type
tdont_return_unowned_from_owned.nim(27, 10) Error: cannot return an owned pointer as an unowned pointer; use 'owned(Obj)' as the return type
tdont_return_unowned_from_owned.nim(30, 6) Error: type mismatch: got <Obj>
but expected one of:
proc new[T](a: var ref T; finalizer: proc (x: ref T) {.nimcall.})
2 other mismatching symbols have been suppressed; compile with --showAllMismatches:on to see them

expression: new(result)
tdont_return_unowned_from_owned.nim(30, 6) Error: illformed AST:
'''
  errormsg: "illformed AST:"
  line: 30
"""



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

