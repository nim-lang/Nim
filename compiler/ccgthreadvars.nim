#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Thread var support for crappy architectures that lack native support for
## thread local storage. (**Thank you Mac OS X!**)

# included from cgen.nim

proc emulatedThreadVars(conf: ConfigRef): bool =
  result = {optThreads, optTlsEmulation} <= conf.globalOptions

proc accessThreadLocalVar(p: BProc, s: PSym) =
  if emulatedThreadVars(p.config) and not p.threadVarAccessed:
    p.threadVarAccessed = true
    incl p.module.flags, usesThreadVars
    addf(p.procSec(cpsLocals), "\tNimThreadVars* NimTV_;$n", [])
    add(p.procSec(cpsInit),
      ropecg(p.module, "\tNimTV_ = (NimThreadVars*) #GetThreadLocalVars();$n", []))

proc declareThreadVar(m: BModule, s: PSym, isExtern: bool) =
  if emulatedThreadVars(m.config):
    # we gather all thread locals var into a struct; we need to allocate
    # storage for that somehow, can't use the thread local storage
    # allocator for it :-(
    if not containsOrIncl(m.g.nimtvDeclared, s.id):
      m.g.nimtvDeps.add(s.loc.t)
      addf(m.g.nimtv, "$1 $2;$n", [getTypeDesc(m, s.loc.t), s.loc.r])
  else:
    if isExtern: add(m.s[cfsVars], "extern ")
    if optThreads in m.config.globalOptions: add(m.s[cfsVars], "NIM_THREADVAR ")
    add(m.s[cfsVars], getTypeDesc(m, s.loc.t))
    addf(m.s[cfsVars], " $1;$n", [s.loc.r])

proc generateThreadLocalStorage(m: BModule) =
  if m.g.nimtv != nil and (usesThreadVars in m.flags or sfMainModule in m.module.flags):
    for t in items(m.g.nimtvDeps): discard getTypeDesc(m, t)
    addf(m.s[cfsSeqTypes], "typedef struct {$1} NimThreadVars;$n", [m.g.nimtv])

proc generateThreadVarsSize(m: BModule) =
  if m.g.nimtv != nil:
    let externc = if m.config.cmd == cmdCompileToCpp or
                       sfCompileToCpp in m.module.flags: "extern \"C\" "
                  else: ""
    addf(m.s[cfsProcs],
      "$#NI NimThreadVarsSize(){return (NI)sizeof(NimThreadVars);}$n",
      [externc.rope])
