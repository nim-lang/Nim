#
#
#           The Nim Compiler
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Opt-in instrumentation for the IC backend, enabled with `-d:icBNodeProf`.
## Off, every template below is `discard` and nothing is linked in.
##
## It lives in its own module with NO compiler imports so that any stage can
## use it without creating a cycle — `ast2nif` for the loader, `nifbackend` for
## the stage phases, `cgen` for what happens per routine.
##
## Each backend process appends ONE line to `$NIM_IC_BNODE_PROF` at exit (or to
## stderr when that is unset), because a `--ic:on` build fans out a process per
## module per stage and interleaved writes would tear. Use `-d:icNoParallel`
## when the numbers need to be attributable to a particular module.
##
## Counts are for volume, timings for cost, and the two answer different
## questions: a call count alone once pointed at the wrong accessor (700k calls
## worth 8ms) while the real cost was 259k `info` resolutions worth 1.36s.

when defined(icBNodeProf):
  import std / [envvars, exitprocs, syncio, monotimes]
  from std / times import inNanoseconds

  type
    ProfSlot* = enum
      pTyp, pIfaceExported, pIfaceHidden, pIfaceModules,
      pTopNodes, pExportSyms, pPeekKind, pPeekFallback, pPeekLoaded,
      pTopToolingSkip
    TimeSlot* = enum
      tLoadClosure, tModuleId, tBifLoad, tPosIndex, tTopLevel, tInterfTables,
      tTransform, tGenBody, tExportBranch, tResolveSym, tEnumFields,
      # Coarse phases, added to find where a backend process spends the time
      # that none of the slots above account for. `tStage` is the whole stage
      # body, so `Process - tStage` is everything before it: exec, the Nim
      # runtime, config replay, `registerNifSuffix`/graph setup.
      tStage,
      tLowerOwned, tLowerHooks, tLowerWrite,
      tCgGen, tCgInit, tCgFinish, tCgWrite,
      tMergeStage, tEmitRender, tLinkStage,
      # `nim m` (the frontend): the sem pass as a whole, and writing the module's
      # `.s.bif`. `Stage - WriteNif - <the loading slots>` is then sem proper.
      tWriteNif,
      # `processTopLevel`'s branches: which part of a module HEADER costs what.
      tTopReplay, tTopLogOps, tTopOffers, tTopStmts

  let procStart = getMonoTime()
    ## Set when this module initialises, i.e. essentially at process start, so
    ## the dump can report total process wall time and the startup share can be
    ## derived as `Process - Stage`.

  var profStageName* = "frontend"
    ## Which invocation this is: the backend stage name, or "frontend" for a
    ## `nim m` process, which arms the profiler through ast2nif but never enters
    ## a backend stage. Without it the `Process - Stage` startup figure is
    ## meaningless — 204 frontend processes' whole runtime lands in it.

  var profCounts: array[ProfSlot, int]
  var profNanos: array[TimeSlot, int64]
  var profStart: array[TimeSlot, MonoTime]
  var profArmed = false

  proc profDump() =
    var line = "BNODEPROF stage=" & profStageName
    for s in ProfSlot: line.add " " & ($s)[1..^1] & "=" & $profCounts[s]
    for s in TimeSlot: line.add " " & ($s)[1..^1] & "ms=" & $(profNanos[s] div 1_000_000)
    line.add " Processms=" & $((getMonoTime() - procStart).inNanoseconds div 1_000_000)
    let f = getEnv("NIM_IC_BNODE_PROF")
    if f.len > 0:
      let h = open(f, fmAppend)
      h.writeLine line
      h.close()
    else:
      stderr.writeLine line

  template armProf() =
    if not profArmed:
      profArmed = true
      addExitProc profDump

  template prof*(s: ProfSlot; n = 1) =
    armProf()
    inc profCounts[s], n
  template icProfStart*(s: TimeSlot) =
    armProf()
    profStart[s] = getMonoTime()
  template icProfStop*(s: TimeSlot) =
    profNanos[s] += (getMonoTime() - profStart[s]).inNanoseconds

  template timed*(s: TimeSlot; body: untyped) =
    ## Leaf timing. NOT re-entrant, and the phase slots are not disjoint —
    ## `tTransform` contains body materialization. Read them as nested, not
    ## additive.
    ##
    ## Arms the dump like `prof`/`icProfStart` do. It did not, and so a process
    ## whose ONLY instrumentation is a `timed` never reported at all: the
    ## `merge`, `emit` and `link` stages were silently absent from every profile.
    armProf()
    let t0 = getMonoTime()
    body
    profNanos[s] += (getMonoTime() - t0).inNanoseconds
else:
  template prof*(s: untyped; n = 1) = discard
  template icProfStart*(s: untyped) = discard
  template icProfStop*(s: untyped) = discard
  template timed*(s: untyped; body: untyped) = body
