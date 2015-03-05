#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Profiling support for Nim. This is an embedded profiler that requires
## ``--profiler:on``. You only need to import this module to get a profiling
## report at program exit.

when not defined(profiler) and not defined(memProfiler):
  {.warning: "Profiling support is turned off!".}

# We don't want to profile the profiling code ...
{.push profiler: off.}

import hashes, algorithm, strutils, tables, sets

when not defined(memProfiler):
  include "system/timers"

const
  withThreads = compileOption("threads")
  tickCountCorrection = 50_000

when not declared(system.TStackTrace):
  type TStackTrace = array [0..20, cstring]

# We use a simple hash table of bounded size to keep track of the stack traces:
type
  TProfileEntry = object
    total: int
    st: TStackTrace
  TProfileData = array [0..64*1024-1, ptr TProfileEntry]

proc `==`(a, b: TStackTrace): bool =
  for i in 0 .. high(a):
    if a[i] != b[i]: return false
  result = true

# XXX extract this data structure; it is generally useful ;-)
# However a chain length of over 3000 is suspicious...
var
  profileData: TProfileData
  emptySlots = profileData.len * 3 div 2
  maxChainLen = 0
  totalCalls = 0

when not defined(memProfiler):
  var interval: TNanos = 5_000_000 - tickCountCorrection # 5ms

  proc setSamplingFrequency*(intervalInUs: int) =
    ## set this to change the sampling frequency. Default value is 5ms.
    ## Set it to 0 to disable time based profiling; it uses an imprecise
    ## instruction count measure instead then.
    if intervalInUs <= 0: interval = 0
    else: interval = intervalInUs * 1000 - tickCountCorrection

when withThreads:
  import locks
  var
    profilingLock: TLock

  initLock profilingLock

proc hookAux(st: TStackTrace, costs: int) =
  # this is quite performance sensitive!
  when withThreads: acquire profilingLock
  inc totalCalls
  var last = high(st)
  while last > 0 and isNil(st[last]): dec last
  var h = hash(pointer(st[last])) and high(profileData)

  # we use probing for maxChainLen entries and replace the encountered entry
  # with the minimal 'total' value:
  if emptySlots == 0:
    var minIdx = h
    var probes = maxChainLen
    while probes >= 0:
      if profileData[h].st == st:
        # wow, same entry found:
        inc profileData[h].total, costs
        return
      if profileData[minIdx].total < profileData[h].total:
        minIdx = h
      h = ((5 * h) + 1) and high(profileData)
      dec probes
    profileData[minIdx].total = costs
    profileData[minIdx].st = st
  else:
    var chain = 0
    while true:
      if profileData[h] == nil:
        profileData[h] = cast[ptr TProfileEntry](
                             allocShared0(sizeof(TProfileEntry)))
        profileData[h].total = costs
        profileData[h].st = st
        dec emptySlots
        break
      if profileData[h].st == st:
        # wow, same entry found:
        inc profileData[h].total, costs
        break
      h = ((5 * h) + 1) and high(profileData)
      inc chain
    maxChainLen = max(maxChainLen, chain)
  when withThreads: release profilingLock

when defined(memProfiler):
  const
    SamplingInterval = 50_000
  var
    gTicker {.threadvar.}: int

  proc hook(st: TStackTrace, size: int) {.nimcall.} =
    if gTicker == 0:
      gTicker = -1
      when defined(ignoreAllocationSize):
        hookAux(st, 1)
      else:
        hookAux(st, size)
      gTicker = SamplingInterval
    dec gTicker

else:
  var
    t0 {.threadvar.}: TTicks

  proc hook(st: TStackTrace) {.nimcall.} =
    if interval == 0:
      hookAux(st, 1)
    elif int64(t0) == 0 or getTicks() - t0 > interval:
      hookAux(st, 1)
      t0 = getTicks()

proc getTotal(x: ptr TProfileEntry): int =
  result = if isNil(x): 0 else: x.total

proc cmpEntries(a, b: ptr TProfileEntry): int =
  result = b.getTotal - a.getTotal

proc `//`(a, b: int): string =
  result = format("$1/$2 = $3%", a, b, formatFloat(a / b * 100.0, ffDefault, 2))

proc writeProfile() {.noconv.} =
  when declared(system.TStackTrace):
    system.profilerHook = nil
  const filename = "profile_results.txt"
  echo "writing " & filename & "..."
  var f: File
  if open(f, filename, fmWrite):
    sort(profileData, cmpEntries)
    writeln(f, "total executions of each stack trace:")
    var entries = 0
    for i in 0..high(profileData):
      if profileData[i] != nil: inc entries

    var perProc = initCountTable[string]()
    for i in 0..entries-1:
      var dups = initSet[string]()
      for ii in 0..high(TStackTrace):
        let procname = profileData[i].st[ii]
        if isNil(procname): break
        let p = $procname
        if not containsOrIncl(dups, p):
          perProc.inc(p, profileData[i].total)

    var sum = 0
    # only write the first 100 entries:
    for i in 0..min(100, entries-1):
      if profileData[i].total > 1:
        inc sum, profileData[i].total
        writeln(f, "Entry: ", i+1, "/", entries, " Calls: ",
          profileData[i].total // totalCalls, " [sum: ", sum, "; ",
          sum // totalCalls, "]")
        for ii in 0..high(TStackTrace):
          let procname = profileData[i].st[ii]
          if isNil(procname): break
          writeln(f, "  ", procname, " ", perProc[$procname] // totalCalls)
    close(f)
    echo "... done"
  else:
    echo "... failed"

var
  disabled: int

proc disableProfiling*() =
  when declared(system.TStackTrace):
    atomicDec disabled
    system.profilerHook = nil

proc enableProfiling*() =
  when declared(system.TStackTrace):
    if atomicInc(disabled) >= 0:
      system.profilerHook = hook

when declared(system.TStackTrace):
  system.profilerHook = hook
  addQuitProc(writeProfile)

{.pop.}
