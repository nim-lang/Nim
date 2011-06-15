#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Thread var support for crappy architectures that lack native support for 
## thread local storage.

proc AccessThreadLocalVar(p: BProc, s: PSym) =
  if optThreads in gGlobalOptions:
    if platform.OS[targetOS].props.contains(ospLacksThreadVars):
      if not p.ThreadVarAccessed:
        p.ThreadVarAccessed = true
        p.module.usesThreadVars = true
        appf(p.s[cpsLocals], "NimThreadVars* NimTV;$n")
        appcg(p, cpsInit, "NimTV=(NimThreadVars*)#GetThreadLocalVars();$n")

var
  nimtv: PRope # nimrod thread vars
  nimtvDeps: seq[PType] = @[]
  nimtvDeclared = initIntSet()

proc emulatedThreadVars(): bool {.inline.} =
  result = optThreads in gGlobalOptions and
    platform.OS[targetOS].props.contains(ospLacksThreadVars)

proc declareThreadVar(m: BModule, s: PSym, isExtern: bool) =
  if emulatedThreadVars():
    # we gather all thread locals var into a struct; we need to allocate
    # storage for that somehow, can't use the thread local storage
    # allocator for it :-(
    if not containsOrIncl(nimtvDeclared, s.id):
      nimtvDeps.add(s.loc.t)
      appf(nimtv, "$1 $2;$n", [getTypeDesc(m, s.loc.t), s.loc.r])
  else:
    if isExtern: app(m.s[cfsVars], "extern ")
    if optThreads in gGlobalOptions: app(m.s[cfsVars], "NIM_THREADVAR ")
    app(m.s[cfsVars], getTypeDesc(m, s.loc.t))
    appf(m.s[cfsVars], " $1;$n", [s.loc.r])
  
proc generateThreadLocalStorage(m: BModule) =
  if nimtv != nil and (m.usesThreadVars or sfMainModule in m.module.flags):
    for t in items(nimtvDeps): discard getTypeDesc(m, t)
    appf(m.s[cfsSeqTypes], "typedef struct {$1} NimThreadVars;$n", [nimtv])

proc GenerateThreadVarsSize(m: BModule) =
  if nimtv != nil:
    app(m.s[cfsProcs], 
      "NI NimThreadVarsSize(){return (NI)sizeof(NimThreadVars);}" & tnl)

