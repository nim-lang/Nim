discard """
errormsg: "'blk.p(a)' has nil child at index 1"
action: reject
"""
import macros

type BlockLiteral[T] = object
  p: T

proc p[T](a:int) = echo 1
proc p[T](a:string) = echo "a"

iterator arguments(formalParams: NimNode): NimNode =
  var iParam = 0
  for i in 1 ..< formalParams.len:
    let pp = formalParams[i]
    for j in 0 .. pp.len - 3:
      yield pp[j]
      inc iParam

macro implementInvoke(T: typedesc): untyped =
  let t = getTypeImpl(T)[1]

  let call = newCall(newDotExpr(ident"blk", ident"p"))
  let params = copyNimTree(t[0])
  result = newProc(ident"invoke", body = call)
  # result[2] = newTree(nnkGenericParams,T)
  for n in arguments(params):
    call.add(n)
  
  params.insert(1, newIdentDefs(ident"blk", newTree(nnkBracketExpr, bindSym"BlockLiteral", T)))
  result.params = params

proc getInvoke(T: typedesc) =
  implementInvoke(T)


getInvoke(proc(a: int))
