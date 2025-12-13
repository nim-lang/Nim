#
#
#           The Nim Compiler
#        (c) Copyright 2025 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Based on sighashes.nim but works on astdef directly as we need it in ast2nif.nim.
## Also produces more readable names thanks to treemangler.

import std/assertions

import "../dist/nimony/src/lib" / [treemangler]
import "../dist/nimony/src/gear2" / modnames

import astdef, idents, options, lineinfos, msgs
import ic / [enum2nif]

# -------------- Module name handling --------------------------------------------

proc cachedModuleSuffix*(config: ConfigRef; fileIdx: FileIndex): string =
  ## Gets or computes the module suffix for a FileIndex.
  ## For NIF modules, the suffix is already stored in the file info.
  ## For source files, computes it from the path.
  let fullPath = toFullPath(config, fileIdx)
  if fileInfoKind(config, fileIdx) == fikNifModule:
    result = fullPath  # Already a suffix
  else:
    result = moduleSuffix(fullPath, cast[seq[string]](config.searchPaths))

proc modname*(module: int; conf: ConfigRef): string =
  cachedModuleSuffix(conf, module.FileIndex)

proc modname*(module: PSym; conf: ConfigRef): string =
  assert module.kindImpl == skModule
  modname(module.positionImpl, conf)

# --------------- Type key generation --------------------------------------------

type
  ConsiderFlag = enum
    CoProc
    CoType
    CoIgnoreRange
    CoConsiderOwned
    CoDistinct
    CoHashTypeInsideNode

proc typeKey(c: var Mangler, t: PType; flags: set[ConsiderFlag]; conf: ConfigRef)
proc symKey(c: var Mangler, s: PSym; conf: ConfigRef) =
  if sfAnon in s.flagsImpl or s.kindImpl == skGenericParam:
    c.addIdent("´anon")
  else:
    var name = s.name.s
    name.add '.'
    name.addInt s.disamb

    let it =
      if s.kindImpl == skModule:
        s
      elif s.kindImpl in skProcKinds and sfFromGeneric in s.flagsImpl and s.ownerFieldImpl.kindImpl != skModule:
        s.ownerFieldImpl.ownerFieldImpl
      else:
        s.ownerFieldImpl
    if it.kindImpl == skModule:
      name.add '.'
      name.add modname(it, conf)
    c.addSymbol(name)

proc treeKey(c: var Mangler, n: PNode; flags: set[ConsiderFlag]; conf: ConfigRef) =
  if n == nil:
    c.addEmpty()
    return

  let k = n.kind
  case k
  of nkEmpty, nkNilLit, nkType: discard
  of nkIdent:
    c.addIdent(n.ident.s)
  of nkSym:
    symKey(c, n.sym, conf)
    if CoHashTypeInsideNode in flags and n.sym.typImpl != nil:
      typeKey(c, n.sym.typImpl, flags, conf)
  of nkCharLit..nkUInt64Lit:
    let v = n.intVal
    c.addIntLit v
  of nkFloatLit..nkFloat64Lit:
    let v = n.floatVal
    c.addFloatLit v
  of nkStrLit..nkTripleStrLit:
    c.addStrLit n.strVal
  else:
    withTree c, toNifTag(k):
      for i in 0..<n.len: treeKey(c, n[i], flags, conf)

proc skipModifierB(n: PType): PType {.inline.} =
  n.sonsImpl[^1]

proc skipTypesB(t: PType, kinds: TTypeKinds): PType =
  result = t
  while result.kind in kinds: result = result.sonsImpl[^1]

proc isGenericAlias(t: PType): bool =
  result = t.kind == tyGenericInst and t.skipModifierB.skipTypesB({tyAlias}).kind == tyGenericInst

proc skipGenericAlias(t: PType): PType =
  result = t.skipTypesB({tyAlias})
  if result.isGenericAlias:
    result = result.skipModifierB.skipTypesB({tyAlias})

proc maybeImported(c: var Mangler, s: PSym; conf: ConfigRef) {.inline.} =
  if s != nil and {sfImportc, sfExportc} * s.flagsImpl != {}:
    c.symKey(s, conf)

proc typeKey(c: var Mangler, t: PType; flags: set[ConsiderFlag]; conf: ConfigRef) =
  if t == nil:
    c.addEmpty()
    return

  case t.kind
  of tyGenericInvocation:
    for a in t.sonsImpl:
      c.typeKey a, flags, conf
  of tyDistinct:
    if CoDistinct in flags:
      if t.symImpl != nil: symKey(c, t.symImpl, conf)
      if t.symImpl == nil or tfFromGeneric in t.flagsImpl:
        c.typeKey t.sonsImpl[^1], flags, conf
    elif CoType in flags or t.symImpl == nil:
      c.typeKey t.sonsImpl[^1], flags, conf
    else:
      symKey(c, t.symImpl, conf)
  of tyGenericInst:
    if sfInfixCall in t.sonsImpl[0].symImpl.flagsImpl:
      # This is an imported C++ generic type.
      # We cannot trust the `lastSon` to hold a properly populated and unique
      # value for each instantiation, so we hash the generic parameters here:
      let normalizedType = t.skipGenericAlias
      c.typeKey normalizedType.sonsImpl[0], flags, conf
      for i in 1..<t.sonsImpl.len-1:
        c.typeKey t.sonsImpl[i], flags, conf
    else:
      c.typeKey t.skipModifierB, flags, conf
  of tyAlias, tySink, tyUserTypeClasses, tyInferred:
    c.typeKey t.skipModifierB, flags, conf
  of tyOwned:
    if CoConsiderOwned in flags:
      withTree c, toNifTag(t.kind):
        c.typeKey t.skipModifierB, flags, conf
    else:
      c.typeKey t.skipModifierB, flags, conf
  of tyBool:
    withTree c, "bool":
      maybeImported(c, t.symImpl, conf)
  of tyChar:
    withTree c, "c":
      c.addIntLit 8 # char is always 8 bits
      maybeImported(c, t.symImpl, conf)
  of tyInt:
    withTree c, "i":
      c.addIntLit -1
      maybeImported(c, t.symImpl, conf)
  of tyInt8:
    withTree c, "i":
      c.addIntLit 8
      maybeImported(c, t.symImpl, conf)
  of tyInt16:
    withTree c, "i":
      c.addIntLit 16
      maybeImported(c, t.symImpl, conf)
  of tyInt32:
    withTree c, "i":
      c.addIntLit 32
      maybeImported(c, t.symImpl, conf)
  of tyInt64:
    withTree c, "i":
      c.addIntLit 64
      maybeImported(c, t.symImpl, conf)
  of tyUInt:
    withTree c, "u":
      c.addIntLit -1
      maybeImported(c, t.symImpl, conf)
  of tyUInt8:
    withTree c, "u":
      c.addIntLit 8
      maybeImported(c, t.symImpl, conf)
  of tyUInt16:
    withTree c, "u":
      c.addIntLit 16
      maybeImported(c, t.symImpl, conf)
  of tyUInt32:
    withTree c, "u":
      c.addIntLit 32
      maybeImported(c, t.symImpl, conf)
  of tyUInt64:
    withTree c, "u":
      c.addIntLit 64
      maybeImported(c, t.symImpl, conf)
  of tyObject, tyEnum:
    if t.typeInstImpl != nil:
      # prevent against infinite recursions here, see bug #8883:
      let inst = t.typeInstImpl
      t.typeInstImpl = nil # IC: spurious writes are ok since we set it back immediately
      assert inst.kind == tyGenericInst
      c.typeKey inst.sonsImpl[0], flags, conf
      for i in 1..<inst.sonsImpl.len-1:
        c.typeKey inst.sonsImpl[i], flags, conf
      t.typeInstImpl = inst
    elif t.symImpl != nil:
      c.symKey(t.symImpl, conf)
    else:
      c.addIdent "`bug"
  of tyFromExpr:
    withTree c, toNifTag(t.kind):
      c.treeKey(t.nImpl, flags, conf)
  of tyTuple:
    withTree c, toNifTag(t.kind):
      if t.nImpl != nil and CoType notin flags:
        for i in 0..<t.nImpl.len:
          withTree c, "kv":
            assert(t.nImpl[i].kind == nkSym)
            c.symKey(t.nImpl[i].sym, conf)
            c.typeKey(t.nImpl[i].sym.typImpl, flags+{CoIgnoreRange}, conf)
      else:
        for i in 1..<t.sonsImpl.len:
          c.typeKey t.sonsImpl[i], flags+{CoIgnoreRange}, conf
  of tyRange:
    if CoIgnoreRange notin flags:
      withTree c, toNifTag(t.kind):
        c.treeKey(t.nImpl, {}, conf)
        c.typeKey(t.sonsImpl[^1], flags, conf)
    else:
      c.typeKey(t.sonsImpl[^1], flags, conf)
  of tyStatic:
    withTree c, toNifTag(t.kind):
      c.treeKey(t.nImpl, {}, conf)
      c.typeKey(t.skipModifierB, flags, conf)
  of tyProc:
    withTree c, (if tfIterator in t.flagsImpl: "itertype" else: "proctype"):
      if CoProc in flags and t.nImpl != nil:
        let params = t.nImpl
        for i in 1..<params.len:
          let param = params[i].sym
          c.symKey(param, conf)
          c.typeKey(param.typImpl, flags, conf)
      else:
        for i in 1..<t.sonsImpl.len:
          c.typeKey(t.sonsImpl[i], flags, conf)
      if t.sonsImpl.len > 0:
        c.typeKey(t.sonsImpl[0], flags, conf)

      c.addIdent toNifTag(t.callConvImpl)
      if tfVarargs in t.flagsImpl: c.addIdent "´varargs"
  of tyArray:
    withTree c, toNifTag(t.kind):
      c.typeKey(t.sonsImpl[^1], flags-{CoIgnoreRange}, conf)
      c.typeKey(t.sonsImpl[0], flags-{CoIgnoreRange}, conf)
  else:
    withTree c, toNifTag(t.kind):
      for i in 1..<t.sonsImpl.len:
        c.typeKey t.sonsImpl[i], flags, conf
      if tfNotNil in t.flagsImpl and CoType notin flags: c.addIdent "´notnil"

proc typeKey*(t: PType; conf: ConfigRef): string =
  var c = createMangler(30, -1)
  typeKey(c, t, {}, conf)
  result = c.extract()
