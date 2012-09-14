#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Profiling support for Nimrod. This is an embedded profiler that requires
## ``--profiler:on``. You only need to import this module to get a profiling
## report at program exit.

when not defined(profiler):
  {.error: "Profiling support is turned off!".}

# We don't want to profile the profiling code ...
{.push profiler: off.}

import hashes, algorithm, strutils

# We use a simple hash table of bounded size to keep track of the stack traces:
type
  TProfileEntry = object
    total: int
    st: system.TStackTrace
  TProfileData = array [0..64*1024-1, ref TProfileEntry]

proc `==`(a, b: TStackTrace): bool =
  for i in 0 .. high(a):
    if a[i] != b[i]: return false
  result = true

# XXX extract this data structure; it is generally useful ;-)
var
  profileData: TProfileData
  emptySlots = profileData.len * 3 div 2
  maxChainLen = 0
  totalCalls = 0

proc hook(st: system.TStackTrace) {.nimcall.} =
  # this is quite performance sensitive!
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
        inc profileData[h].total
        return
      if profileData[minIdx].total < profileData[h].total:
        minIdx = h
      h = ((5 * h) + 1) and high(profileData)
      dec probes
    profileData[minIdx].total = 1
    profileData[minIdx].st = st
  else:
    var chain = 0
    while true:
      if profileData[h] == nil:
        GC_disable()
        new profileData[h]
        GC_enable()
        profileData[h].total = 1
        profileData[h].st = st
        dec emptySlots
        maxChainLen = max(maxChainLen, chain)
        return
      if profileData[h].st == st:
        # wow, same entry found:
        inc profileData[h].total
        maxChainLen = max(maxChainLen, chain)
        return
      h = ((5 * h) + 1) and high(profileData)
      inc chain

proc getTotal(x: ref TProfileEntry): int =
  result = if isNil(x): 0 else: x.total

proc cmpEntries(a, b: ref TProfileEntry): int =
  result = b.getTotal - a.getTotal

proc writeProfile() {.noconv.} =
  stopProfiling()
  const filename = "profile_results"
  var f: TFile
  var j = 1
  while open(f, filename & $j & ".txt"):
    close(f)
    inc(j)
  let filen = filename & $j & ".txt"
  echo "writing ", filen, "..."
  if open(f, filen, fmWrite):
    sort(profileData, cmpEntries)
    writeln(f, "total executions of each stack trace:")
    var entries = 0
    for i in 0..high(profileData):
      if profileData[i] != nil: inc entries
    
    var sum = 0
    # only write the first 100 entries:
    for i in 0..min(100, high(profileData)):
      if profileData[i] != nil and profileData[i].total > 1:
        inc sum, profileData[i].total
        writeln(f, "Entry: ", i, "/", entries, " Calls: ",
          profileData[i].total, "/", totalCalls, " [sum: ", sum, "; ",
          formatFloat(sum / totalCalls * 100.0, ffDefault, 2), "%]")
        for ii in 0..high(TStackTrace):
          let procname = profileData[i].st[ii]
          if isNil(procname): break
          writeln(f, "  ", procname)
    close(f)
  echo "... done"

system.profilerHook = hook
addQuitProc(writeProfile)

{.pop.}
