import

  ast, astalgo

import

  std / deques

type
  SomeNode* = object
    case kind*: TNodeKind
    of nkSym:
      sym: PSym
    of nkType:
      typ: PType
    of nkNone:
      node: PNode
    else:
      discard

  NodeDeque* = Deque[SomeNode]

proc isEmpty*(d: NodeDeque): bool =
  result = d.len == 0

proc isNil*(n: SomeNode): bool =
  block:
    case n.kind
    of nkNone:
      if n.node != nil:
        break
    of nkSym:
      if n.sym != nil:
        break
    of nkType:
      if n.typ != nil:
        break
    else:
      raise newException(Defect, "unexpected node kind")
    result = true

proc isValid*(n: SomeNode): bool  =
  if n.isNil:
    raise newException(Defect, "nil node")
  result = true

proc asType*(n: SomeNode): PType =
  assert n.kind == nkType
  assert n.isValid
  result = n.typ

proc asSym*(n: SomeNode): PSym =
  assert n.kind == nkSym
  assert n.isValid
  result = n.sym

proc asNode*(n: SomeNode): PNode =
  assert n.kind == nkNone
  assert n.isValid
  result = n.node

proc newSomeNode*(p: PNode): SomeNode = SomeNode(kind: nkNone, node: p)
proc newSomeNode*(p: PSym): SomeNode = SomeNode(kind: nkSym, sym: p)
proc newSomeNode*(p: PType): SomeNode = SomeNode(kind: nkType, typ: p)

proc getModule*(n: SomeNode): PSym =
  case n.kind
  of nkSym:
    result = getModule(n.sym)
  of nkType:
    result = getModule(n.typ)
  of nkNone:
    result = getModule(n.node)
  else:
    raise newException(Defect, "unexpected type")
