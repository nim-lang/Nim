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

  type
    ProfSlot* = enum
      pKind, pTagKindHit, pTagKindMiss, pAstChildren, pSkip, pSon, pLen,
      pLastSon, pIterYield, pSym, pTyp, pTypTagLit, pOrigin, pNilType,
      pGenBodyCalls, pInfo
    TimeSlot* = enum
      tLoadClosure, tModuleId, tBifLoad, tPosIndex, tTopLevel, tInterfTables,
      tTransform, tHandOff, tGenBody, tAnalyses,
      tSym, tTyp, tInfo, tOrigin

  var profCounts: array[ProfSlot, int]
  var profNanos: array[TimeSlot, int64]
  var profStart: array[TimeSlot, MonoTime]
  var profArmed = false

  proc profDump() =
    var line = "BNODEPROF"
    for s in ProfSlot: line.add " " & ($s)[1..^1] & "=" & $profCounts[s]
    for s in TimeSlot: line.add " " & ($s)[1..^1] & "ms=" & $(profNanos[s] div 1_000_000)
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
    ## `tTransform` contains body materialization, `tTyp` reaches `tSym`. Read
    ## them as nested, not additive.
    let t0 = getMonoTime()
    body
    profNanos[s] += (getMonoTime() - t0).inNanoseconds
else:
  template prof*(s: untyped; n = 1) = discard
  template icProfStart*(s: untyped) = discard
  template icProfStop*(s: untyped) = discard
  template timed*(s: untyped; body: untyped) = body
