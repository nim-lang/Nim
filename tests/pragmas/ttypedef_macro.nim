import macros

macro makeref(s): untyped =
  expectKind s, nnkTypeDef
  result = newTree(nnkTypeDef, s[0], s[1], newTree(nnkRefTy, s[2]))

type
  Obj {.makeref.} = object
    a: int

doAssert Obj is ref
doAssert Obj(a: 3)[].a == 3

macro multiply(amount: static int, s): untyped =
  let name = $s[0].basename
  result = newNimNode(nnkTypeSection)
  for i in 1 .. amount:
    result.add(newTree(nnkTypeDef, ident(name & $i), s[1], s[2]))

type
  Foo = object
  Bar {.multiply: 2.} = object
    x, y, z: int
  Baz = object

let bar1 = Bar1(x: 1, y: 2, z: 3)
let bar2 = Bar2(x: bar1.x, y: bar1.y, z: bar1.z)
doAssert Bar1 isnot Bar2
doAssert not declared(Bar)
doAssert not declared(Bar3)

# https://github.com/nim-lang/RFCs/issues/219

macro inferKind(td): untyped =
  let name = $td[0].basename
  var rhs = td[2]
  while rhs.kind in {nnkPtrTy, nnkRefTy}: rhs = rhs[0]
  if rhs.kind != nnkObjectTy:
    result = td
  else:
    for n in rhs[^1]:
      if n.kind == nnkRecCase and n[0][^2].eqIdent"_":
        let kindTypeName = ident(name & "Kind")
        let en = newTree(nnkEnumTy, newEmptyNode())
        for i in 1 ..< n.len:
          let branch = n[i]
          if branch.kind == nnkOfBranch:
            for j in 0 ..< branch.len - 1:
              en.add(branch[j])
        n[0][^2] = kindTypeName
        return newTree(nnkTypeSection,
          newTree(nnkTypeDef, kindTypeName, newEmptyNode(), en),
          td)

type Node {.inferKind.} = ref object
  case kind: _
  of opValue: value: int
  of opAdd, opSub, opMul, opCall: kids: seq[Node]

doAssert opValue is NodeKind
let node = Node(kind: opMul, kids: @[
  Node(kind: opValue, value: 3),
  Node(kind: opValue, value: 5)
])
doAssert node.kind == opMul
doAssert node.kids[0].value * node.kids[1].value == 15
