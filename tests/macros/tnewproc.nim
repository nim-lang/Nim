import macros

macro test(a: untyped): untyped =
  # proc hello*(x: int = 3, y: float32): int {.inline.} = discard
  let
    nameNode = nnkPostfix.newTree(
      newIdentNode("*"),
      newIdentNode("hello")
    )
    params = @[
      newIdentNode("int"),
      nnkIdentDefs.newTree(
        newIdentNode("x"),
        newIdentNode("int"),
        newLit(3)
      ),
      nnkIdentDefs.newTree(
        newIdentNode("y"),
        newIdentNode("float32"),
        newEmptyNode()
      )
    ]
    paramsNode = nnkFormalParams.newTree(params)
    pragmasNode = nnkPragma.newTree(
      newIdentNode("inline")
    )
    bodyNode = nnkStmtList.newTree(
      nnkDiscardStmt.newTree(
        newEmptyNode()
      )
    )

  var
    expected = nnkProcDef.newTree(
      nameNode,
      newEmptyNode(),
      newEmptyNode(),
      paramsNode,
      pragmasNode,
      newEmptyNode(),
      bodyNode
    )

  doAssert expected == newProc(name=nameNode, params=params,
                                    body = bodyNode, pragmas=pragmasNode)
  expected.pragma = newEmptyNode()
  doAssert expected == newProc(name=nameNode, params=params,
                                    body = bodyNode)

test:
  42
