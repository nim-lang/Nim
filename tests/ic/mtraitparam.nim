import std/macros

type
  Chunk* = ref object
    x*: int32
  ChunkTrait* = distinct tuple[
    loaded: proc(self: pointer, chunk: Chunk)
  ]

macro makeVTable*(traitType: typedesc): untyped =
  ## Splice the param symbols out of an imported proc type into a fresh proc
  ## type nested in a fresh tuple type. Under `nim ic` the imported trait is
  ## loaded from a NIF cache, so its param symbols are `Sealed`; re-owning them
  ## in `semProcTypeNode` used to trip `ast.nim` `s.state != Sealed`.
  var t = traitType.getTypeInst[1].getTypeImpl
  if t.kind == nnkDistinctTy: t = t[0]
  let formalParams = t[0][1][0]
  var bridgeParams = nnkFormalParams.newTree(formalParams[0].copyNimTree)
  bridgeParams.add nnkIdentDefs.newTree(ident"p", ident"pointer", newEmptyNode())
  for j in 2 ..< formalParams.len:
    bridgeParams.add formalParams[j].copyNimTree
  let vtType = nnkTupleTy.newTree(
    nnkIdentDefs.newTree(ident"m0",
      nnkProcTy.newTree(bridgeParams, nnkPragma.newTree(ident"nimcall")),
      newEmptyNode()))
  let vtName = genSym(nskType, "VT")
  let vtVar = genSym(nskVar, "vt")
  result = nnkStmtList.newTree(
    nnkTypeSection.newTree(
      nnkTypeDef.newTree(vtName, newEmptyNode(), vtType)),
    nnkVarSection.newTree(
      nnkIdentDefs.newTree(
        nnkPragmaExpr.newTree(vtVar, nnkPragma.newTree(ident"used")),
        vtName, newEmptyNode())))
