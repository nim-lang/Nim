type
  Snippet = string
  Builder = string

template newBuilder(s: string): Builder =
  s

proc addField(obj: var Builder; typ, name: Snippet; pragmas: Snippet = "") =
  if pragmas.len != 0:
    obj.add(pragmas)
    obj.add(" ")
  obj.add(typ)
  obj.add(" ")
  obj.add(name)
  obj.add(";\n")

template addFieldWithType(obj: var Builder; name: Snippet; body: typed) =
  body
  obj.add(" ")
  obj.add(name)
  obj.add(";\n")

proc addField(obj: var Builder; field: PSym; name, typ: Snippet; isFlexArray: bool; initializer: Snippet) =
  if field.alignment > 0:
    obj.add("NIM_ALIGN(")
    obj.addInt(field.alignment)
    obj.add(")")
  obj.add(typ)
  if sfNoalias in field.flags:
    obj.add(" NIM_NOALIAS")
  obj.add(" ")
  obj.add(name)
  if isFlexArray:
    obj.add("[SEQ_DECL_SIZE]")
  if field.bitsize != 0:
    obj.add(":")
    obj.addInt(field.bitsize)
  if initializer.len != 0:
    obj.add(initializer)
  obj.add(";\n")

proc structOrUnion(t: PType): Snippet =
  let t = t.skipTypes({tyAlias, tySink})
  if tfUnion in t.flags: "union"
  else: "struct"

proc ptrType(t: Snippet): Snippet =
  t & "*"

template addStruct(obj: var Builder; m: BModule; typ: PType; name: string; baseType: string; body: typed) =
  if tfPacked in typ.flags:
    if hasAttribute in CC[m.config.cCompiler].props:
      obj.add(structOrUnion(typ))
      obj.add(" __attribute__((__packed__))")
    else:
      obj.add("#pragma pack(push, 1)\n")
      obj.add(structOrUnion(typ))
  else:
    obj.add(structOrUnion(typ))
  obj.add(" ")
  obj.add(name)
  type BaseClassKind = enum
    bcNone, bcCppInherit, bcSupField, bcNoneRtti, bcNoneTinyRtti
  var baseKind: BaseClassKind
  if typ.kind == tyObject:
    if typ.baseClass == nil:
      if lacksMTypeField(typ):
        baseKind = bcNone
      elif optTinyRtti in m.config.globalOptions:
        baseKind = bcNoneTinyRtti
      else:
        baseKind = bcNoneRtti
    elif m.compileToCpp:
      baseKind = bcCppInherit
    else:
      baseKind = bcSupField
  if baseKind == bcCppInherit:
    obj.add(" : public ")
    obj.add(baseType)
  obj.add(" ")
  obj.add("{\n")
  let currLen = obj.len
  case baseKind
  of bcNone, bcCppInherit: discard
  of bcNoneRtti:
    obj.addField(name = "m_type", typ = ptrType(cgsymValue(m, "TNimType")))
  of bcNoneTinyRtti:
    obj.addField(name = "m_type", typ = ptrType(cgsymValue(m, "TNimTypeV2")))
  of bcSupField:
    obj.addField(name = "Sup", typ = baseType)
  body
  if typ.itemId notin m.g.graph.memberProcsPerType:
    if currLen == obj.len:
      # no fields were added, add dummy field
      obj.addField(name = "dummy", typ = "char")
    elif typ.n != nil and typ.n.len == 1 and typ.n[0].kind == nkSym and
        typ.n[0].sym.typ.skipTypes(abstractInst).kind == tyUncheckedArray:
      # only consists of flexible array field, add dummy field
      obj.addField(name = "dummy", typ = "char")
  obj.add("};\n")
  if tfPacked in typ.flags and hasAttribute notin CC[m.config.cCompiler].props:
    result.add("#pragma pack(pop)\L")

template addAnonStruct(obj: var Builder; m: BModule; parentTyp: PType; body: typed) =
  if tfPacked in parentTyp.flags:
    if hasAttribute in CC[m.config.cCompiler].props:
      obj.add("struct __attribute__((__packed__)) {\n")
    else:
      obj.add("#pragma pack(push, 1)\nstruct {")
  else:
    obj.add("struct {\n")
  let currLen = obj.len
  body
  obj.add("};\n")
  if tfPacked in parentTyp.flags and hasAttribute notin CC[m.config.cCompiler].props:
    result.add("#pragma pack(pop)\L")

template addAnonUnion(obj: var Builder; body: typed) =
  obj.add "union{\n"
  body
  obj.add("};\n")
