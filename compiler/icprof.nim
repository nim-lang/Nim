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
## use it without creating a cycle — `bnode` needs it for the accessors,
## `nifbackend` for the stage phases, `cgen` for what happens per routine.
##
## Each backend process appends ONE line to `$NIM_IC_BNODE_PROF` at exit (or to
## stderr when that is unset), because a `--ic:on` build fans out a process per
## module per stage and interleaved writes would tear. Use `-d:icNoParallel`
## when the numbers need to be attributable to a particular module.
##
## Counts are for volume, timings for cost, and the two answer different
## questions: the accessors turned out to be 700k calls worth 8ms, while `info`
## was 259k calls worth 1.36s. Neither number alone would have found that.

when defined(icBNodeProf):
  import std / [envvars, exitprocs, syncio, monotimes]
  from std / times import inNanoseconds
  when defined(posix):
    import std / posix

  type
    ProfSlot* = enum
      pKind, pTagKindHit, pTagKindMiss, pAstChildren, pSkip, pSon, pLen,
      pLastSon, pIterYield, pSym, pTyp, pTypTagLit, pOrigin, pNilType,
      pGenBodyCalls, pInfo, pIfaceExported, pIfaceHidden, pIfaceModules,
      pTopNodes, pExportSyms, pPeekKind, pPeekFallback, pPeekLoaded,
      pTopToolingSkip,
      pBifLoads, pSemBufLoads   ## `.bif` files opened; of which `.s.bif` companions
    TimeSlot* = enum
      tLoadClosure, tModuleId, tBifLoad, tPosIndex, tTopLevel, tInterfTables,
      tTransform, tHandOff, tGenBody, tAnalyses,
      tSym, tTyp, tInfo, tOrigin, tExportBranch, tResolveSym, tEnumFields,
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
      # doc/parallel_compiler.md §1: the unit of parallelism it proposes is one
      # top-level routine body, so its whole case rests on what share of a
      # module those bodies are. Both are `timedOutermost` regions — a body
      # re-enters `semProcAux` for every nested routine, instance and lambda it
      # drags in, and those belong to their top-level owner, not to a count of
      # their own. Read `SemBodyms / SemModulems` for the share, `SemBodyn` for
      # how many units a module has and `SemBodymaxus` for the critical path
      # inside one.
      tSemBody, tSemModule,
      # `processTopLevel`'s branches: which part of a module HEADER costs what.
      tTopReplay, tTopLogOps, tTopOffers, tTopStmts
    MemSlot* = enum
      ## Heap snapshots (`getOccupiedMem`, MB) at the points that split a
      ## process's memory by WHAT it holds: what the dependency closure's load
      ## left behind, what generating the batch added on top, and what was
      ## live at the end.
      mAfterClosure, mAfterGen, mAfterFinish, mAtExit

  let procStart = getMonoTime()
    ## Set when this module initialises, i.e. essentially at process start, so
    ## the dump can report total process wall time and the startup share can be
    ## derived as `Process - Stage`.

  var profStageName* = "frontend"
  var profTag* = ""
    ## What this process worked on — the batch members for a backend stage —
    ## so a line in a parallel build's profile can be traced to its modules.
    ## Which invocation this is: the backend stage name, or "frontend" for a
    ## `nim m` process, which arms the profiler through ast2nif but never enters
    ## a backend stage. Without it the `Process - Stage` startup figure is
    ## meaningless — 204 frontend processes' whole runtime lands in it.

  var profCounts: array[ProfSlot, int]
  var profMem: array[MemSlot, int]
  var profNanos: array[TimeSlot, int64]
  var profMaxNanos: array[TimeSlot, int64]
    ## The largest SINGLE activation of a `timedOutermost` slot. A sum says
    ## what parallelism could remove; the max says what it cannot — it is the
    ## critical path of the region.
  var profRuns: array[TimeSlot, int]
    ## Outermost activations of a `timedOutermost` slot.
  var profDepth: array[TimeSlot, int]
  var profStart: array[TimeSlot, MonoTime]
  var profMemDelta: array[TimeSlot, int64]
    ## Net change of the occupied heap across each timed region, so a slot
    ## says what it ALLOCATED AND KEPT, not only how long it took. Nested the
    ## same way the times are.
  var profMemStart: array[TimeSlot, int64]
  var profArmed = false

  proc profDump() =
    var line = "BNODEPROF stage=" & profStageName
    if profTag.len > 0: line.add " tag=" & profTag
    for s in ProfSlot: line.add " " & ($s)[1..^1] & "=" & $profCounts[s]
    for s in TimeSlot: line.add " " & ($s)[1..^1] & "ms=" & $(profNanos[s] div 1_000_000)
    for s in TimeSlot: line.add " " & ($s)[1..^1] & "dKB=" & $(profMemDelta[s] div 1024)
    # Only the re-entrant slots have these, and only when they ran; every other
    # slot would add two zero fields to every line of every profile.
    for s in TimeSlot:
      if profRuns[s] > 0:
        line.add " " & ($s)[1..^1] & "n=" & $profRuns[s]
        line.add " " & ($s)[1..^1] & "maxus=" & $(profMaxNanos[s] div 1000)
    line.add " Processms=" & $((getMonoTime() - procStart).inNanoseconds div 1_000_000)
    profMem[mAtExit] = getOccupiedMem() div (1024*1024)
    for s in MemSlot: line.add " " & ($s)[1..^1] & "MB=" & $profMem[s]
    when defined(posix):
      # Peak resident set of THIS process, in MB. The memory question is per
      # process: a `cg` process's peak is what a parallel build multiplies.
      var ru = default(Rusage)
      if getrusage(RUSAGE_SELF, addr ru) == 0:
        line.add " PeakRssMB=" & $(ru.ru_maxrss div 1024)
    let f = getEnv("NIM_IC_BNODE_PROF")
    if f.len > 0:
      let h = open(f, fmAppend)
      h.writeLine line
      h.close()
    else:
      stderr.writeLine line
    when defined(nimTypeNames) and not defined(gcOrc) and not defined(gcArc):
      # A per-type heap census (refc builds only: `--mm:refc -d:nimTypeNames`),
      # for when the slots above say WHEN memory grew but not WHAT it is.
      dumpNumberOfInstances()

  template armProf() =
    if not profArmed:
      profArmed = true
      addExitProc profDump

  template prof*(s: ProfSlot; n = 1) =
    armProf()
    inc profCounts[s], n
  template icProfMem*(s: MemSlot) =
    armProf()
    profMem[s] = getOccupiedMem() div (1024*1024)
  template icProfStart*(s: TimeSlot) =
    armProf()
    profStart[s] = getMonoTime()
    profMemStart[s] = getOccupiedMem()
  template icProfStop*(s: TimeSlot) =
    profNanos[s] += (getMonoTime() - profStart[s]).inNanoseconds
    profMemDelta[s] += getOccupiedMem() - profMemStart[s]

  template timed*(s: TimeSlot; body: untyped) =
    ## Leaf timing. NOT re-entrant, and the phase slots are not disjoint —
    ## `tTransform` contains body materialization, `tTyp` reaches `tSym`. Read
    ## them as nested, not additive.
    ##
    ## Arms the dump like `prof`/`icProfStart` do. It did not, and so a process
    ## whose ONLY instrumentation is a `timed` never reported at all: the
    ## `merge`, `emit` and `link` stages were silently absent from every profile.
    armProf()
    let t0 = getMonoTime()
    let m0 = getOccupiedMem()
    body
    profNanos[s] += (getMonoTime() - t0).inNanoseconds
    profMemDelta[s] += getOccupiedMem() - m0

  template timedOutermost*(s: TimeSlot; body: untyped) =
    ## Times the OUTERMOST activation of a re-entrant region and nothing else,
    ## so a nested activation is attributed to its outermost owner instead of
    ## being counted a second time into the same total. That is what makes the
    ## sum comparable to the process's wall time — plain `timed` on
    ## `semProcAux` would report several times the time that actually passed.
    ##
    ## Also records the activation count and the largest single activation,
    ## which is the pair doc/parallel_compiler.md §1 reads as "how many units
    ## are there" and "how long is the longest one".
    armProf()
    let outer = profDepth[s] == 0
    inc profDepth[s]
    let t0 = if outer: getMonoTime() else: default(MonoTime)
    let m0 = if outer: getOccupiedMem() else: 0
    try:
      body
    finally:
      dec profDepth[s]
      if outer:
        let d = (getMonoTime() - t0).inNanoseconds
        profNanos[s] += d
        if d > profMaxNanos[s]: profMaxNanos[s] = d
        profMemDelta[s] += getOccupiedMem() - m0
        inc profRuns[s]
else:
  template prof*(s: untyped; n = 1) = discard
  template icProfStart*(s: untyped) = discard
  template icProfMem*(s: untyped) = discard
  template icProfStop*(s: untyped) = discard
  template timed*(s: untyped; body: untyped) = body
  template timedOutermost*(s: untyped; body: untyped) = body
