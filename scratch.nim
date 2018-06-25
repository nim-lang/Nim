import macros

proc unpackTypedesc(arg: NimNode): NimNode =
  let typeInst = arg.getTypeInst
  typeInst.expectKind nnkBracketExpr
  if not typeInst[0].eqIdent "typeDesc":
    error("expect typeDesc", arg)
  typeInst[1]

macro genImpl(arg: typed): untyped =
  nnkObjectTy.newTree(
    newEmptyNode(),
    newEmptyNode(),
    nnkRecList.newTree(
      nnkIdentDefs.newTree(
        newIdentNode("a"),
        newIdentNode("int"),
        newEmptyNode()
      ),
      nnkIdentDefs.newTree(
        newIdentNode("b"),
        newIdentNode("float32"),
        newEmptyNode()
      ),
      nnkIdentDefs.newTree(
        newIdentNode("c"),
        newIdentNode("string"),
        newEmptyNode()
      ),
      nnkIdentDefs.newTree(
        newIdentNode("d"),
        arg.unpackTypedesc,
        newEmptyNode()
      )
    )
  )

type
  MyGeneric[T] = genImpl(T)

var myType: MyGeneric[int]

echo myType
