# included from nifencoder

proc writeTypeFlags(c: var EncodeContext; t: PType) =
  writeFlags c.b, t.flags, "tf"

proc isNominalRef(t: PType): bool {.inline.} =
  let e = t.elementType
  t.sym != nil and e.kind == tyObject and (e.sym == nil or sfAnon in e.sym.flags)

template singleElement(keyw: string) {.dirty.} =
  c.b.withTree keyw:
    writeTypeFlags(c, t)
    if t.hasElementType:
      toNif c, t.elementType
    else:
      c.b.addEmpty

proc atom(c: var EncodeContext; t: PType; tag: string) =
  c.b.withTree tag:
    writeTypeFlags(c, t)

proc atom(c: var EncodeContext; t: PType) =
  c.b.withTree toNifTag(t.kind):
    writeTypeFlags(c, t)

template typeHead(c: var EncodeContext; t: PType; body: untyped) =
  c.b.withTree toNifTag(t.kind):
    writeTypeFlags(c, t)
    body

proc toNif(c: var EncodeContext; t: PType; isTypeSection = false) =
  if t == nil:
    c.b.addKeyw "missing"
    return

  case t.kind
  of tyNone: atom c, t
  of tyBool: atom c, t
  of tyChar: atom c, t, "c +8"
  of tyEmpty: c.b.addEmpty
  of tyInt: atom c, t, "i -1"
  of tyInt8: atom c, t, "i +8"
  of tyInt16: atom c, t, "i +16"
  of tyInt32: atom c, t, "i +32"
  of tyInt64: atom c, t, "i +64"
  of tyUInt: atom c, t, "u -1"
  of tyUInt8: atom c, t, "u +8"
  of tyUInt16: atom c, t, "u +16"
  of tyUInt32: atom c, t, "u +32"
  of tyUInt64: atom c, t, "u +64"
  of tyFloat, tyFloat64: atom c, t, "f -1"
  of tyFloat32: atom c, t, "f +32"
  of tyFloat128: atom c, t, "f +128"
  of tyAlias:
    c.typeHead t:
      toNif c, t.skipModifier
  of tyNil: atom c, t
  of tyUntyped: atom c, t
  of tyTyped: atom c, t
  of tyTypeDesc:
    c.typeHead t:
      if t.kidsLen == 0 or t.elementType.kind == tyNone:
        c.b.addEmpty
      else:
        toNif c, t.elementType
  of tyGenericParam:
    # See the nim-sem spec:
    c.typeHead t:
      symToNif c, t.sym
      #c.b.addIntLit t.sym.position

  of tyGenericInst:
    c.typeHead t:
      toNif c, t.genericHead
      for _, a in t.genericInstParams:
        toNif c, a
  of tyGenericInvocation:
    c.typeHead t:
      toNif c, t.genericHead
      for _, a in t.genericInvocationParams:
        toNif c, a
  of tyGenericBody:
    #toNif c, t.last
    c.typeHead t:
      for _, son in t.ikids: toNif c, son
  of tyEnum:
    if isTypeSection:
      c.typeHead t:
        for son in t.n:
          symdefToNif c, son
    else:
      symToNif c, t.sym
  of tyDistinct:
    if isTypeSection:
      c.typeHead t:
        for son in t.kids:
          toNif c, son
    else:
      symToNif c, t.sym
  of tyPtr:
    if isNominalRef(t):
      symToNif c, t.sym
    else:
      c.typeHead t:
        toNif c, t.elementType
  of tyRef:
    if isNominalRef(t):
      symToNif c, t.sym
    else:
      c.typeHead t:
        toNif c, t.elementType
  of tyVar:
    c.b.withTree(if isOutParam(t): "out" else: "mut"):
      toNif c, t.elementType
  of tyAnd:
    c.typeHead t:
      for _, son in t.ikids: toNif c, son
  of tyOr:
    c.typeHead t:
      for _, son in t.ikids: toNif c, son
  of tyNot:
    c.typeHead t: toNif c, t.elementType

  of tyFromExpr:
    if t.n == nil:
      atom c, t, "err"
    else:
      c.typeHead t:
        toNif c, t.n

  of tyArray:
    c.typeHead t:
      if t.hasElementType:
        toNif c, t.elementType
        toNif c, t.indexType
      else:
        c.b.addEmpty 2
  of tyUncheckedArray:
    c.typeHead t:
      if t.hasElementType:
        toNif c, t.elementType
      else:
        c.b.addEmpty

  of tySequence:
    singleElement toNifTag(t.kind)

  of tyOrdinal:
    c.typeHead t:
      if t.hasElementType:
        toNif c, t.skipModifier
      else:
        c.b.addEmpty

  of tySet: singleElement toNifTag(t.kind)
  of tyOpenArray: singleElement toNifTag(t.kind)
  of tyIterable: singleElement toNifTag(t.kind)
  of tyLent: singleElement toNifTag(t.kind)

  of tyTuple:
    c.typeHead t:
      if t.n != nil:
        for i in 0..<t.n.len:
          assert(t.n[i].kind == nkSym)
          c.b.withTree "kv":
            c.b.addIdent t.n[i].sym.name.s
            toNif c, t.n[i].sym.typ
      else:
        for _, son in t.ikids: toNif c, son

  of tyRange:
    c.typeHead t:
      toNif c, t.elementType
      if t.n != nil and t.n.kind == nkRange and t.n.len == 2:
        toNif c, t.n[0]
        toNif c, t.n[1]
      else:
        c.b.addEmpty 2

  of tyProc:
    let kind = if tfIterator in t.flags: "iteratortype"
               else: "proctype"
    c.b.withTree kind:

      c.b.addEmpty # name
      for i, a in t.paramTypes:
        let j = paramTypeToNodeIndex(i)
        if t.n != nil and j < t.n.len and t.n[j].kind == nkSym:
          c.b.addIdent(t.n[j].sym.name.s)
          toNif c, a
      if tfUnresolved in t.flags:
        c.b.addRaw "[*missing parameters*]"
      if t.returnType != nil:
        toNif c, t.returnType
      else:
        c.b.addEmpty

      c.b.withTree "effects":
        # XXX model explicit .raises and .tags annotations
        if tfNoSideEffect in t.flags:
          c.b.addKeyw "noside"
        if tfThread in t.flags:
          c.b.addKeyw "gcsafe"

      c.b.withTree "pragmas":
        if t.callConv == ccNimCall and tfExplicitCallConv notin t.flags:
          discard "no calling convention to generate"
        else:
          c.b.addKeyw toNifTag(t.callConv)

  of tyVarargs:
    c.typeHead t:
      if t.hasElementType:
        toNif c, t.elementType
      else:
        c.b.addEmpty
      if t.n != nil:
        toNif c, t.n
      else:
        c.b.addEmpty

  of tySink: singleElement toNifTag(t.kind)
  of tyOwned: singleElement toNifTag(t.kind)
  of tyVoid: atom c, t
  of tyPointer: atom c, t
  of tyString: atom c, t
  of tyCstring: atom c, t
  of tyObject: symToNif c, t.sym
  of tyForward: atom c, t
  of tyError: atom c, t
  of tyBuiltInTypeClass:
    # XXX See what to do with this.
    c.typeHead t:
      if t.kidsLen == 0 or t.genericHead.kind == tyNone:
        c.b.addEmpty
      else:
        toNif c, t.genericHead

  of tyUserTypeClass, tyConcept:
    # ^ old style concept.  ^ new style concept.
    if t.sym != nil:
      symToNif c, t.sym
    else:
      atom c, t, "err"
  of tyUserTypeClassInst:
    # "instantiated" old style concept. Whatever that even means.
    if t.sym != nil:
      symToNif c, t.sym
    else:
      atom c, t, "err"
  of tyCompositeTypeClass: toNif c, t.last
  of tyInferred: toNif c, t.skipModifier
  of tyAnything: atom c, t
  of tyStatic:
    c.typeHead t:
      if t.hasElementType:
        toNif c, t.skipModifier
      else:
        c.b.addEmpty
      if t.n != nil:
        toNif c, t.n
      else:
        c.b.addEmpty
