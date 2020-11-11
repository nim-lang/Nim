import macros,json

var decls{.compileTime.}: seq[NimNode] = @[]
var impls{.compileTime.}: seq[NimNode] = @[]

macro importImpl_forward(name, returns: untyped): untyped =
  result = newNimNode(nnkEmpty)
  var func_name = newNimNode(nnkAccQuoted)
  func_name.add newIdentNode("import")
  func_name.add name

  var res = newNimNode(nnkProcDef)
  res.add newNimNode(nnkPostfix)
  res[0].add newIdentNode("*")
  res[0].add func_name
  res.add newNimNode(nnkEmpty)
  res.add newNimNode(nnkEmpty)
  res.add newNimNode(nnkFormalParams)
  res[3].add returns
  var p1 = newNimNode(nnkIdentDefs)
  p1.add newIdentNode("dat")
  p1.add newIdentNOde("JsonNode")
  p1.add newNimNode(nnkEmpty)
  res[3].add p1
  var p2 = newNimNode(nnkIdentDefs)
  p2.add newIdentNode("errors")
  p2.add newNimNode(nnkVarTy)
  p2.add newNimNode(nnkEmpty)
  p2[1].add newNimNode(nnkBracketExpr)
  p2[1][0].add newIdentNode("seq")
  p2[1][0].add newIdentNode("string")
  res[3].add p2

  res.add newNimNode(nnkEmpty)
  res.add newNimNode(nnkEmpty)
  res.add newNimNode(nnkEmpty)

  decls.add res
  echo(repr(res))

macro importImpl(name, returns, body: untyped) =
  #var res = getAST(importImpl_forward(name, returns))
  discard getAST(importImpl_forward(name, returns))
  var res = copyNimTree(decls[decls.high])
  res[6] = body
  echo repr(res)
  impls.add res

macro okayy() =
  result = newNimNode(nnkStmtList)
  for node in decls: result.add node
  for node in impls: result.add node

importImpl(Item, int):
  echo 42
importImpl(Foo, int16):
  echo 77

okayy
