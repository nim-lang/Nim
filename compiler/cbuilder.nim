type
  Snippet = string
  Builder = string

template newBuilder(s: string): Builder =
  s

proc addField(obj: var Builder; name, typ: Snippet; isFlexArray: bool = false; initializer: Snippet = "") =
  obj.add('\t')
  obj.add(typ)
  obj.add(" ")
  obj.add(name)
  if isFlexArray:
    obj.add("[SEQ_DECL_SIZE]")
  if initializer.len != 0:
    obj.add(initializer)
  obj.add(";\n")

proc addField(obj: var Builder; field: PSym; name, typ: Snippet; isFlexArray: bool = false; initializer: Snippet = "") =
  ## for fields based on an `skField` symbol
  obj.add('\t')
  if field.alignment > 0:
    obj.add("NIM_ALIGN(")
    obj.addInt(field.alignment)
    obj.add(") ")
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

type
  BaseClassKind = enum
    bcNone, bcCppInherit, bcSupField, bcNoneRtti, bcNoneTinyRtti
  StructBuilderInfo = object
    baseKind: BaseClassKind
    preFieldsLen: int

proc structOrUnion(t: PType): Snippet =
  let t = t.skipTypes({tyAlias, tySink})
  if tfUnion in t.flags: "union"
  else: "struct"

proc ptrType(t: Snippet): Snippet =
  t & "*"

proc startSimpleStruct(obj: var Builder; m: BModule; name: string; baseType: Snippet): StructBuilderInfo =
  result = StructBuilderInfo(baseKind: bcNone)
  obj.add("struct ")
  obj.add(name)
  if baseType.len != 0:
    if m.compileToCpp:
      result.baseKind = bcCppInherit
    else:
      result.baseKind = bcSupField
  if result.baseKind == bcCppInherit:
    obj.add(" : public ")
    obj.add(baseType)
  obj.add(" ")
  obj.add("{\n")
  result.preFieldsLen = obj.len
  if result.baseKind == bcSupField:
    obj.addField(name = "Sup", typ = baseType)

proc finishSimpleStruct(obj: var Builder; m: BModule; info: StructBuilderInfo) =
  if info.baseKind == bcNone and info.preFieldsLen == obj.len:
    # no fields were added, add dummy field
    obj.addField(name = "dummy", typ = "char")
  obj.add("};\n")

template addSimpleStruct(obj: var Builder; m: BModule; name: string; baseType: Snippet; body: typed) =
  ## for independent structs, not directly based on a Nim type
  let info = startSimpleStruct(obj, m, name, baseType)
  body
  finishSimpleStruct(obj, m, info)

proc startStruct(obj: var Builder; m: BModule; t: PType; name: string; baseType: Snippet): StructBuilderInfo =
  result = StructBuilderInfo(baseKind: bcNone)
  if tfPacked in t.flags:
    if hasAttribute in CC[m.config.cCompiler].props:
      obj.add(structOrUnion(t))
      obj.add(" __attribute__((__packed__))")
    else:
      obj.add("#pragma pack(push, 1)\n")
      obj.add(structOrUnion(t))
  else:
    obj.add(structOrUnion(t))
  obj.add(" ")
  obj.add(name)
  if t.kind == tyObject:
    if t.baseClass == nil:
      if lacksMTypeField(t):
        result.baseKind = bcNone
      elif optTinyRtti in m.config.globalOptions:
        result.baseKind = bcNoneTinyRtti
      else:
        result.baseKind = bcNoneRtti
    elif m.compileToCpp:
      result.baseKind = bcCppInherit
    else:
      result.baseKind = bcSupField
  elif baseType.len != 0:
    if m.compileToCpp:
      result.baseKind = bcCppInherit
    else:
      result.baseKind = bcSupField
  if result.baseKind == bcCppInherit:
    obj.add(" : public ")
    obj.add(baseType)
  obj.add(" ")
  obj.add("{\n")
  result.preFieldsLen = obj.len
  case result.baseKind
  of bcNone:
    # rest of the options add a field or don't need it due to inheritance,
    # we need to add the dummy field for uncheckedarray ahead of time
    # so that it remains trailing
    if t.itemId notin m.g.graph.memberProcsPerType and
        t.n != nil and t.n.len == 1 and t.n[0].kind == nkSym and
        t.n[0].sym.typ.skipTypes(abstractInst).kind == tyUncheckedArray:
      # only consists of flexible array field, add *initial* dummy field
      obj.addField(name = "dummy", typ = "char")
  of bcCppInherit: discard
  of bcNoneRtti:
    obj.addField(name = "m_type", typ = ptrType(cgsymValue(m, "TNimType")))
  of bcNoneTinyRtti:
    obj.addField(name = "m_type", typ = ptrType(cgsymValue(m, "TNimTypeV2")))
  of bcSupField:
    obj.addField(name = "Sup", typ = baseType)

proc finishStruct(obj: var Builder; m: BModule; t: PType; info: StructBuilderInfo) =
  if info.baseKind == bcNone and info.preFieldsLen == obj.len and
      t.itemId notin m.g.graph.memberProcsPerType:
    # no fields were added, add dummy field
    obj.addField(name = "dummy", typ = "char")
  obj.add("};\n")
  if tfPacked in t.flags and hasAttribute notin CC[m.config.cCompiler].props:
    obj.add("#pragma pack(pop)\n")

template addStruct(obj: var Builder; m: BModule; typ: PType; name: string; baseType: Snippet; body: typed) =
  ## for structs built directly from a Nim type
  let info = startStruct(obj, m, typ, name, baseType)
  body
  finishStruct(obj, m, typ, info)

template addFieldWithStructType(obj: var Builder; m: BModule; parentTyp: PType; fieldName: string, body: typed) =
  ## adds a field with a `struct { ... }` type, building it according to `body`
  obj.add('\t')
  if tfPacked in parentTyp.flags:
    if hasAttribute in CC[m.config.cCompiler].props:
      obj.add("struct __attribute__((__packed__)) {\n")
    else:
      obj.add("#pragma pack(push, 1)\nstruct {")
  else:
    obj.add("struct {\n")
  body
  obj.add("} ")
  obj.add(fieldName)
  obj.add(";\n")
  if tfPacked in parentTyp.flags and hasAttribute notin CC[m.config.cCompiler].props:
    result.add("#pragma pack(pop)\n")

template addAnonUnion(obj: var Builder; body: typed) =
  obj.add "union{\n"
  body
  obj.add("};\n")
