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

proc emulatedThreadVars(): bool =
  result = {optThreads, optTlsEmulation} <= gGlobalOptions

proc accessThreadLocalVar(p: BProc, s: PSym) =
  if emulatedThreadVars() and not p.threadVarAccessed:
    p.threadVarAccessed = true
    p.module.usesThreadVars = true
    addf(p.procSec(cpsLocals), "\tNimThreadVars* NimTV;$n", [])
    add(p.procSec(cpsInit),
      ropecg(p.module, "\tNimTV = (NimThreadVars*) #GetThreadLocalVars();$n"))

var
  nimtv: Rope                 # nimrod thread vars; the struct body
  nimtvDeps: seq[PType] = @[]  # type deps: every module needs whole struct
  nimtvDeclared = initIntSet() # so that every var/field exists only once
                               # in the struct

# 'nimtv' is incredibly hard to modularize! Best effort is to store all thread
# vars in a ROD section and with their type deps and load them
# unconditionally...

# nimtvDeps is VERY hard to cache because it's not a list of IDs nor can it be
# made to be one.

proc declareThreadVar(m: BModule, s: PSym, isExtern: bool) =
  if emulatedThreadVars():
    # we gather all thread locals var into a struct; we need to allocate
    # storage for that somehow, can't use the thread local storage
    # allocator for it :-(
    if not containsOrIncl(nimtvDeclared, s.id):
      nimtvDeps.add(s.loc.t)
      addf(nimtv, "$1 $2;$n", [getTypeDesc(m, s.loc.t), s.loc.r])
  else:
    if isExtern: add(m.s[cfsVars], "extern ")
    if optThreads in gGlobalOptions: add(m.s[cfsVars], "NIM_THREADVAR ")
    add(m.s[cfsVars], getTypeDesc(m, s.loc.t))
    addf(m.s[cfsVars], " $1;$n", [s.loc.r])

proc generateThreadLocalStorage(m: BModule) =
  if nimtv != nil and (m.usesThreadVars or sfMainModule in m.module.flags):
    for t in items(nimtvDeps): discard getTypeDesc(m, t)
    addf(m.s[cfsSeqTypes], "typedef struct {$1} NimThreadVars;$n", [nimtv])

proc generateThreadVarsSize(m: BModule) =
  if nimtv != nil:
    let externc = if gCmd != cmdCompileToCpp and
                       sfCompileToCpp in m.module.flags: "extern \"C\""
                  else: ""
    addf(m.s[cfsProcs],
      "$#NI NimThreadVarsSize(){return (NI)sizeof(NimThreadVars);}$n",
      [externc.rope])
