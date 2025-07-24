discard """
  cmd: "nim check --newruntime --hints:off $file"
  nimout: '''
tdont_return_unowned_from_owned.nim(26, 13) Error: assignment produces a dangling ref: the unowned ref lives longer than the owned ref
tdont_return_unowned_from_owned.nim(27, 13) Error: assignment produces a dangling ref: the unowned ref lives longer than the owned ref
tdont_return_unowned_from_owned.nim(31, 10) Error: cannot return an owned pointer as an unowned pointer; use 'owned(RootRef)' as the return type
tdont_return_unowned_from_owned.nim(43, 10) Error: cannot return an owned pointer as an unowned pointer; use 'owned(Obj)' as the return type
tdont_return_unowned_from_owned.nim(46, 10) Error: cannot return an owned pointer as an unowned pointer; use 'owned(Obj)' as the return type
tdont_return_unowned_from_owned.nim(49, 6) Error: type mismatch: got <Obj>
but expected one of:
proc new[T](a: var ref T; finalizer: proc (x: ref T) {.nimcall.})
  first type mismatch at position: 2
  missing parameter: finalizer
2 other mismatching symbols have been suppressed; compile with --showAllMismatches:on to see them

expression: new(result)
tdont_return_unowned_from_owned.nim(49, 6) Error: illformed AST: 
'''
  errormsg: "illformed AST:"
"""



proc testA(result: var (RootRef, RootRef)) =
  let r: owned RootRef = RootRef()
  result[0] = r
  result[1] = RootRef()

proc testB(): RootRef =
  let r: owned RootRef = RootRef()
  result = r





## line 30
# bug #11073
type
  Obj = ref object

proc newObjA(): Obj =
  result = new Obj

proc newObjB(): Obj =
  result = Obj()

proc newObjC(): Obj =
  new(result) # illFormedAst raises GlobalError,
              # without pipeline parsing, it needs to placed at the end
              # in case that it disturbs other errors

let a = newObjA()
let b = newObjB()
let c = newObjC()

