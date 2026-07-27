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

import std/[assertions, sets]

import "../dist/nimony/src/lib" / [treemangler]
import icmodnames

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
    CoPrecise                 # produce a FRONTEND-faithful, unique key (for the
                              # stable NIF *name*, not hook dedup): keep distinctions
                              # sem makes that the backend identity collapses — e.g.
                              # an `int literal(x)` type carries its value so it does
                              # not merge with `int`. See `getTypeKey`/`typeKeyHook`.

  TypeLoader* = proc (t: PType) {.nimcall.}
  SymLoader* = proc (s: PSym) {.nimcall.}
  Context = object
    m: Mangler
    tl: TypeLoader
    sl: SymLoader
    visited: HashSet[ItemId]  # anonymous object types whose fields are currently
                              # being hashed — a non-mutating guard against endless
                              # recursion when a field references the type itself.

proc typeKey(c: var Context; t: PType; flags: set[ConsiderFlag]; conf: ConfigRef)
proc symKey(c: var Context; s: PSym; conf: ConfigRef) =
  if s.state == Partial:
    assert c.sl != nil
    c.sl(s)
  if sfAnon in s.flagsImpl or s.kindImpl == skGenericParam:
    c.m.addIdent("´anon")
  else:
    var name = s.name.s
    name.add '.'
    name.addInt s.disamb

    # The owner may still be an unloaded stub (kind `skStub`): force it in
    # before inspecting its kind, otherwise the module suffix is silently
    # dropped from the key and def-vs-use keys diverge — e.g. `Lexer`'s base
    # class keyed as `TBaseLexer.0.` at nifc vs `TBaseLexer.0.nimqydn3y` at
    # sem time, making `getAttachedOp` miss ("'=destroy' operator not found").
    template forceLoaded(x: PSym): PSym =
      let tmp = x
      if tmp != nil and tmp.state == Partial and c.sl != nil: c.sl(tmp)
      tmp

    let owner = forceLoaded(s.ownerFieldImpl)
    let it =
      if s.kindImpl == skModule:
        s
      elif s.kindImpl in skProcKinds and sfFromGeneric in s.flagsImpl and
           owner != nil and owner.kindImpl != skModule:
        forceLoaded(owner.ownerFieldImpl)
      else:
        owner
    if it != nil and it.kindImpl == skModule:
      name.add '.'
      name.add modname(it, conf)
    c.m.addSymbol(name)

proc treeKey(c: var Context; n: PNode; flags: set[ConsiderFlag]; conf: ConfigRef) =
  if n == nil:
    c.m.addEmpty()
    return

  let k = n.kind
  case k
  of nkEmpty, nkNilLit, nkType: discard
  of nkIdent:
    c.m.addIdent(n.ident.s)
  of nkSym:
    symKey(c, n.sym, conf)
    if CoHashTypeInsideNode in flags and n.sym.typImpl != nil:
      typeKey(c, n.sym.typImpl, flags, conf)
  of nkCharLit..nkUInt64Lit:
    let v = n.intVal
    c.m.addIntLit v
  of nkFloatLit..nkFloat64Lit:
    let v = n.floatVal
    c.m.addFloatLit v
  of nkStrLit..nkTripleStrLit:
    c.m.addStrLit n.strVal
  else:
    withTree c.m, toNifTag(k):
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

proc maybeImported(c: var Context; s: PSym; conf: ConfigRef) {.inline.} =
  if s != nil and {sfImportc, sfExportc} * s.flagsImpl != {}:
    c.symKey(s, conf)

proc emitPreciseFlags(c: var Context; t: PType; flags: set[ConsiderFlag]) {.inline.} =
  ## Under CoPrecise the NIF *name* must be as fine as `types.sameType`, which
  ## compares `eqTypeFlags * flags` (see `sameFlags`). Without this a
  ## `proc() {.gcsafe.}` keyed identically to `proc()`, and a `ref X not nil`
  ## identically to `ref X` — the loader would then merge two frontend-distinct
  ## types onto one NIF name. Emitted only for the naming path (CoPrecise); the
  ## `setAttachedOp` hook key (no CoPrecise) is unaffected, so its byte layout is
  ## unchanged.
  if CoPrecise in flags:
    let ef = eqTypeFlags * t.flagsImpl
    if ef != {}:
      withTree c.m, "´tflags":
        for f in ef: c.m.addIntLit ord(f)

proc backendTypeName(t: PType; conf: ConfigRef): string =
  ## Stable cross-module identity of a backend-minted (lower-stage) type: its
  ## serialized `@bk` NIF name (mirrors ast2nif.nifTypeName). A closure-env
  ## object/ref minted by the `lower` stage has NO stable STRUCTURAL key — its
  ## captured-field types re-resolve to different modules in the producing vs the
  ## consuming process (e.g. field `x0` → `int` in the producer, → the consumer's
  ## alias in the consumer) — but this name (kind + item + home-module suffix) is
  ## identical in both, because the consumer loads the producer's name verbatim.
  ## Keying hooks by it makes producer `setAttachedOp` and consumer `getAttachedOp`
  ## agree. The trailing `@bk` (= ast2nif.BackendLocalMarker) keeps it disjoint
  ## from any normal type's structural key.
  result = "`t"
  result.addInt ord(t.kind)
  result.add '.'
  result.addInt t.uniqueId.item
  result.add '.'
  result.add modname(t.uniqueId.module, conf)
  result.add "@bk"

proc typeKey(c: var Context; t: PType; flags: set[ConsiderFlag]; conf: ConfigRef) =
  if t == nil:
    c.m.addEmpty()
    return

  if t.state == Partial:
    assert c.tl != nil
    c.tl(t)

  if t.uniqueId.isBackendMinted:
    # Backend-minted (lower-stage) closure-env types key by their stable NIF name,
    # never by structure (which diverges across the NIF boundary). An env `ref`
    # that is itself NOT backend-minted still keys stably: it recurses here and
    # reaches its `@bk` object, which short-circuits to a stable name.
    c.m.addSymbol backendTypeName(t, conf)
    return

  case t.kind
  of tyGenericInvocation:
    for a in t.sonsImpl:
      c.typeKey a, flags, conf
  of tyDistinct:
    if t.sonsImpl.len == 0:
      # a bare `distinct` typeclass (e.g. `foo(distinct, ...)` matched
      # against a `T: type` param) has no base type to key — it IS its kind
      withTree c.m, toNifTag(t.kind):
        c.m.addEmpty()
    elif CoDistinct in flags:
      if t.symImpl != nil: symKey(c, t.symImpl, conf)
      if t.symImpl == nil or tfFromGeneric in t.flagsImpl:
        c.typeKey t.sonsImpl[^1], flags, conf
    elif CoType in flags or t.symImpl == nil:
      c.typeKey t.sonsImpl[^1], flags, conf
    else:
      symKey(c, t.symImpl, conf)
  of tyGenericInst:
    # The generic head (son[0]) may be a lazily-loaded stub under IC; ensure it
    # is materialised before peeking at its symbol. A nil sym means this is not
    # an imported C++ generic, so fall through to the normal `skipModifierB`.
    var base = t.sonsImpl[0]
    if base.state == Partial:
      assert c.tl != nil
      c.tl(base)
    if base.symImpl != nil and sfInfixCall in base.symImpl.flagsImpl:
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
      withTree c.m, toNifTag(t.kind):
        c.typeKey t.skipModifierB, flags, conf
    else:
      c.typeKey t.skipModifierB, flags, conf
  of tyBool:
    withTree c.m, "bool":
      maybeImported(c, t.symImpl, conf)
  of tyChar:
    withTree c.m, "c":
      c.m.addIntLit 8 # char is always 8 bits
      maybeImported(c, t.symImpl, conf)
  of tyInt:
    withTree c.m, "i":
      c.m.addIntLit -1
      # An `int literal(x)` type (nImpl holds the value) must stay distinct from
      # plain `int` for the NIF name, else overload resolution breaks on reload.
      if CoPrecise in flags and t.nImpl != nil:
        c.m.addIntLit t.nImpl.intVal
      maybeImported(c, t.symImpl, conf)
  of tyInt8:
    withTree c.m, "i":
      c.m.addIntLit 8
      maybeImported(c, t.symImpl, conf)
  of tyInt16:
    withTree c.m, "i":
      c.m.addIntLit 16
      maybeImported(c, t.symImpl, conf)
  of tyInt32:
    withTree c.m, "i":
      c.m.addIntLit 32
      maybeImported(c, t.symImpl, conf)
  of tyInt64:
    withTree c.m, "i":
      c.m.addIntLit 64
      maybeImported(c, t.symImpl, conf)
  of tyUInt:
    withTree c.m, "u":
      c.m.addIntLit -1
      maybeImported(c, t.symImpl, conf)
  of tyUInt8:
    withTree c.m, "u":
      c.m.addIntLit 8
      maybeImported(c, t.symImpl, conf)
  of tyUInt16:
    withTree c.m, "u":
      c.m.addIntLit 16
      maybeImported(c, t.symImpl, conf)
  of tyUInt32:
    withTree c.m, "u":
      c.m.addIntLit 32
      maybeImported(c, t.symImpl, conf)
  of tyUInt64:
    withTree c.m, "u":
      c.m.addIntLit 64
      maybeImported(c, t.symImpl, conf)
  of tyFloat:
    withTree c.m, "f":
      c.m.addIntLit -1
      # A `float literal(x)` type (nImpl = nkFloatLit) must stay distinct from
      # plain `float`, just like the `int literal(x)` case above.
      if CoPrecise in flags and t.nImpl != nil and t.nImpl.kind in {nkFloatLit..nkFloat64Lit}:
        c.m.addFloatLit t.nImpl.floatVal
      maybeImported(c, t.symImpl, conf)
  of tyObject, tyEnum:
    if t.typeInstImpl != nil:
      # prevent against infinite recursions here, see bug #8883:
      let inst = t.typeInstImpl
      if inst.state == Partial:
        # a lazily-loaded typeInst stub has no sons until forced in
        assert c.tl != nil
        c.tl(inst)
      t.typeInstImpl = nil # IC: spurious writes are ok since we set it back immediately
      assert inst.kind == tyGenericInst
      if inst.sonsImpl.len > 0:
        c.typeKey inst.sonsImpl[0], flags, conf
      for i in 1..<inst.sonsImpl.len-1:
        # Match sighashes: generic-instantiation arguments are keyed with
        # `CoDistinct` so distinct args are not collapsed to their base.
        c.typeKey inst.sonsImpl[i], flags+{CoDistinct}, conf
      t.typeInstImpl = inst
    elif t.symImpl != nil:
      c.symKey(t.symImpl, conf)
      # Anonymous / gensym'd object types (e.g. closure environments and
      # `ref object` ObjectTypes) share the placeholder name `´anon`, so `symKey`
      # alone collapses every one of them onto the same key — which made distinct
      # closure-env `=destroy`/`=sink` hooks collide. Mirror sighashes: when the
      # type symbol is anonymous/gensym'd, disambiguate further by keying the
      # field types and names (or `.empty` when there are none).
      template hasFlag(sym: PSym): bool =
        {sfAnon, sfGenSym} * sym.flagsImpl != {}
      if hasFlag(t.symImpl) or
         (t.kind == tyObject and t.ownerFieldImpl != nil and t.ownerFieldImpl.kindImpl == skType and
          t.ownerFieldImpl.typImpl != nil and t.ownerFieldImpl.typImpl.kind == tyRef and hasFlag(t.ownerFieldImpl)):
        if t.nImpl != nil and t.nImpl.len > 0:
          # Guard against endless recursion when a field references this type
          # itself. Unlike sighashes (which temporarily clears `sfAnon`/`sfGenSym`
          # on the symbol), do NOT mutate: `typeKey` runs during sem — it is
          # called unconditionally from `modulegraphs.setAttachedOp` — so a
          # mutation that an assertion deeper in `treeKey` left unrestored would
          # corrupt the type. `symKey` above already emitted the type's identity,
          # so on a back-reference we simply stop.
          if not containsOrIncl(c.visited, t.itemId):
            c.treeKey(t.nImpl, flags + {CoHashTypeInsideNode}, conf)
            c.visited.excl t.itemId
        else:
          c.m.addIdent "´empty"
      # Object inheritance is part of identity: key the base class too.
      if t.kind == tyObject and t.sonsImpl.len > 0 and t.sonsImpl[0] != nil:
        c.typeKey t.sonsImpl[0], flags, conf
    else:
      c.m.addIdent "`bug"
  of tyFromExpr:
    withTree c.m, toNifTag(t.kind):
      c.treeKey(t.nImpl, flags, conf)
  of tyTuple:
    withTree c.m, toNifTag(t.kind):
      if t.nImpl != nil and CoType notin flags:
        for i in 0..<t.nImpl.len:
          withTree c.m, "kv":
            assert(t.nImpl[i].kind == nkSym)
            c.symKey(t.nImpl[i].sym, conf)
            c.typeKey(t.nImpl[i].sym.typImpl, flags+{CoIgnoreRange}, conf)
      else:
        # ALL sons are tuple fields (son 0 included — unlike tyProc, where
        # son 0 is the return type). Starting at 1 dropped the first field,
        # collapsing e.g. `(PSym, NifIndexEntry)` and `(PType, NifIndexEntry)`
        # onto one key, so hook lookup called the wrong `=destroy`/`=sink`
        # (incompatible-argument C errors). Mirrors sighashes' `for a in t.kids`.
        for i in 0..<t.sonsImpl.len:
          c.typeKey t.sonsImpl[i], flags+{CoIgnoreRange}, conf
  of tyRange:
    if t.sonsImpl.len == 0:
      # bare `range` typeclass: no base type, key the kind alone
      withTree c.m, toNifTag(t.kind):
        c.m.addEmpty()
    elif CoIgnoreRange notin flags:
      withTree c.m, toNifTag(t.kind):
        c.treeKey(t.nImpl, {}, conf)
        c.typeKey(t.sonsImpl[^1], flags, conf)
    else:
      c.typeKey(t.sonsImpl[^1], flags, conf)
  of tyStatic:
    withTree c.m, toNifTag(t.kind):
      c.treeKey(t.nImpl, {}, conf)
      if t.sonsImpl.len > 0:
        c.typeKey(t.skipModifierB, flags, conf)
  of tyProc:
    withTree c.m, (if tfIterator in t.flagsImpl: "itertype" else: "proctype"):
      # Proc parameter *types* are part of the type's identity. Under IC the
      # parameters live in `nImpl` (`sonsImpl` holds only the return type), so a
      # loaded proc type has an empty `sonsImpl[1..]`; reading params from there
      # would silently drop them and collide every same-return/same-callconv
      # closure onto one key (e.g. `proc(cb: proc())` onto bare `proc()`),
      # which made hook lookup resolve to the wrong `=copy`. Prefer `nImpl`
      # (consistent in-memory and after load); hash param types only, not their
      # symbols — parameter names do not affect type identity.
      if t.nImpl != nil and t.nImpl.kind == nkFormalParams:
        let params = t.nImpl
        for i in 1..<params.len:
          if params[i].kind == nkSym:
            # The param sym may be a lazily-loaded stub: force it in (as `symKey`
            # does) so its type is available, then hash the param *type* only —
            # parameter names are not part of the type's identity. Without the
            # load the type reads back nil at codegen and the key silently loses
            # its parameters (collapsing distinct closure types onto one key).
            let ps = params[i].sym
            if ps.state == Partial and c.sl != nil: c.sl(ps)
            c.typeKey(ps.typImpl, flags, conf)
          else:
            c.typeKey(params[i].typField, flags, conf)
      else:
        for i in 1..<t.sonsImpl.len:
          c.typeKey(t.sonsImpl[i], flags, conf)
      if t.sonsImpl.len > 0:
        c.typeKey(t.sonsImpl[0], flags, conf)

      c.m.addIdent toNifTag(t.callConvImpl)
      if tfVarargs in t.flagsImpl: c.m.addIdent "´varargs"
      # `.gcsafe`/`.noSideEffect` (in eqTypeFlags) distinguish proc types under
      # sameType, so they must distinguish the NIF name too.
      emitPreciseFlags(c, t, flags)
  of tyArray:
    withTree c.m, toNifTag(t.kind):
      if t.sonsImpl.len == 0:
        # bare `array` typeclass: no element/index types
        c.m.addEmpty()
      else:
        c.typeKey(t.sonsImpl[^1], flags-{CoIgnoreRange}, conf)
        c.typeKey(t.sonsImpl[0], flags-{CoIgnoreRange}, conf)
  else:
    withTree c.m, toNifTag(t.kind):
      for i in 0..<t.sonsImpl.len:
        c.typeKey t.sonsImpl[i], flags, conf
      if tfNotNil in t.flagsImpl and CoType notin flags:
        c.m.addIdent "´notnil"
      # tfNotNil/tfVarIsPtr/tfIsOutParam (eqTypeFlags) part of sameType identity
      # for ref/ptr/var/lent/sink; the hook path (no CoPrecise) keeps its layout.
      emitPreciseFlags(c, t, flags)

proc typeKey*(t: PType; conf: ConfigRef; tl: TypeLoader; sl: SymLoader): string =
  var c: Context = Context(m: createMangler(30, -1), tl: tl, sl: sl,
                           visited: initHashSet[ItemId]())
  # Mirror the flags liftdestructors uses for its `canonTypes` hash
  # (`hashType(skipped, {CoType, CoConsiderOwned, CoDistinct})`): hook keys must
  # distinguish what hook *lifting* distinguishes. With empty flags a generic
  # `distinct` instance (e.g. nilcheck's `SeqOfDistinct[T, U]`) took the bare
  # `symKey` branch — the sym is the generic's and thus SHARED by all
  # instances, so `SeqOfDistinct[I, PNode]` and `SeqOfDistinct[I, Nilability]`
  # collided onto one key and hook lookup returned the wrong `=sink`
  # ("incompatible type for argument" in the generated C). Under `CoDistinct` a
  # `tfFromGeneric` distinct keys as sym + base type, keeping instances apart.
  typeKey(c, t, {CoType, CoConsiderOwned, CoDistinct}, conf)
  result = c.m.extract()
