#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Thread var support for architectures that lack native support for
## thread local storage.

# included from cgen.nim

proc emulatedThreadVars(conf: ConfigRef): bool =
  result = {optThreads, optTlsEmulation} <= conf.globalOptions

proc accessThreadLocalVar(p: BProc, s: PSym) =
  if emulatedThreadVars(p.config) and threadVarAccessed notin p.flags:
    p.flags.incl threadVarAccessed
    incl p.module.flags, usesThreadVars
    p.procSec(cpsLocals).addVar(kind = Local,
      name = "NimTV_",
      typ = ptrType("NimThreadVars"))
    p.procSec(cpsInit).addAssignment("NimTV_",
      cCast(ptrType("NimThreadVars"),
        cCall(cgsymValue(p.module, "GetThreadLocalVars"))))

proc declareThreadVar(m: BModule, s: PSym, isExtern: bool) =
  if emulatedThreadVars(m.config):
    # we gather all thread locals var into a struct; we need to allocate
    # storage for that somehow, can't use the thread local storage
    # allocator for it :-(
    if not containsOrIncl(m.g.nimtvDeclared, s.id):
      m.g.nimtvDeps.add(s.loc.t)
      m.g.nimtv.addField(name = s.loc.snippet, typ = getTypeDesc(m, s.loc.t))
  else:
    let vis =
      if isExtern: Extern
      elif lfExportLib in s.loc.flags: ExportLibVar
      else: Private
    if m.config.cmd == cmdNifC and vis == Private and not isExtern:
      # A `{.threadvar.}`/`{.global.}` thread-local declared inside a routine is
      # emitted by every module that emit-everywhere's its enclosing routine
      # (e.g. libp2p's `var keys {.global.}: HashSet`), so its content-addressed
      # name collides at link. Same fix as a plain global (genGlobalVarDecl):
      # `extern` declaration + a droppable `'d'` definition unit the merge stage
      # assigns one owner. The thread-local storage class rides on both.
      let cname = stripCnifMarks(s.loc.snippet)
      let td = getTypeDesc(m, s.loc.t)
      # `extern` declaration via the full `addVar` overload — it knows the
      # thread-local storage class (`NIM_THREADVAR`); the simple `addVar`'s
      # `addVarHeader` does not implement `Threadvar`.
      m.s[cfsVars].addVar(m, s, name = s.loc.snippet, typ = td,
                          kind = Threadvar, visibility = Extern)
      m.s[cfsVars].add(cnifDefDirective(cname, "d", icNifName(m, s)))
      m.s[cfsVars].addVar(m, s,
        name = s.loc.snippet, typ = td, kind = Threadvar, visibility = vis)
      m.s[cfsVars].add(cnifEndDefs())
    else:
      m.s[cfsVars].addVar(m, s,
        name = s.loc.snippet,
        typ = getTypeDesc(m, s.loc.t),
        kind = Threadvar,
        visibility = vis)

proc generateThreadLocalStorage(m: BModule) =
  if m.g.nimtv.buf.len != 0 and (usesThreadVars in m.flags or sfMainModule in m.module.flags):
    for t in items(m.g.nimtvDeps): discard getTypeDesc(m, t)
    finishTypeDescriptions(m)
    m.s[cfsSeqTypes].addTypedef(name = "NimThreadVars"):
      m.s[cfsSeqTypes].addSimpleStruct(m, name = "", baseType = ""):
        m.s[cfsSeqTypes].add(extract(m.g.nimtv))

proc generateThreadVarsSize(m: BModule) =
  if m.g.nimtv.buf.len != 0:
    let externc = if m.config.backend == backendCpp or
                       sfCompileToCpp in m.module.flags: ExternC
                  else: None
    m.s[cfsProcs].addDeclWithVisibility(externc):
      m.s[cfsProcs].addProcHeader("NimThreadVarsSize", NimInt, cProcParams())
      m.s[cfsProcs].finishProcHeaderWithBody():
        m.s[cfsProcs].addReturn(cCast(NimInt, cSizeof("NimThreadVars")))
