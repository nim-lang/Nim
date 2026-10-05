#
#
#           The Nim Compiler
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## `std/macrocache.CacheCounter` state shared by the `nim m` processes of a
## `nim ic` build. Sibling modules are compiled by separate (possibly parallel)
## processes, so an in-memory counter lets both allocate from the same initial
## state and embed duplicate values (#26201). Instead the counters live in one
## file in the nimcache, guarded by an OS file lock that a process takes on its
## first counter operation and keeps until it is done with its module: `ids.inc;
## ids.value` must observe its own increment, so locking every operation
## separately would not suffice. No process waits on another one while holding
## the lock, so this cannot deadlock.
##
## The file survives across builds and records, per counter, the high-water mark
## and the numbers every process (keyed by its module) was handed. A re-semmed
## module is handed the same numbers again, so a no-op rebuild reproduces its
## artifacts; only a module that needs more numbers than before is given fresh
## ones above the high-water mark. The numbers of one module therefore need not
## be contiguous. They are unique, but unlike under `nim c` neither dense nor
## ordered by import order.

import std/[os, strutils, tables, syncio, assertions]
import ../[options, pathutils]

when defined(windows):
  import std/winlean

  proc lockFileEx(hFile: Handle; flags, reserved, lowLen, highLen: int32;
                  overlapped: ptr OVERLAPPED): WINBOOL {.
      stdcall, dynlib: "kernel32", importc: "LockFileEx".}
  proc unlockFileEx(hFile: Handle; reserved, lowLen, highLen: int32;
                    overlapped: ptr OVERLAPPED): WINBOOL {.
      stdcall, dynlib: "kernel32", importc: "UnlockFileEx".}
  const LockfileExclusiveLock = 2'i32
else:
  proc flock(fd: cint; op: cint): cint {.importc, header: "<sys/file.h>".}
  var LockEx {.importc: "LOCK_EX", header: "<sys/file.h>".}: cint
  var LockUn {.importc: "LOCK_UN", header: "<sys/file.h>".}: cint
  var Eintr {.importc: "EINTR", header: "<errno.h>".}: cint

proc lockExclusive(f: File) =
  when defined(windows):
    var ov = default(OVERLAPPED)
    if lockFileEx(Handle(getOsFileHandle(f)), LockfileExclusiveLock, 0, 1, 0,
                  addr ov) == 0:
      raiseOSError(osLastError())
  else:
    while flock(getOsFileHandle(f), LockEx) != 0:
      let err = osLastError()
      if err != OSErrorCode(Eintr): raiseOSError(err)

proc unlock(f: File) =
  when defined(windows):
    var ov = default(OVERLAPPED)
    discard unlockFileEx(Handle(getOsFileHandle(f)), 0, 1, 0, addr ov)
  else:
    discard flock(getOsFileHandle(f), LockUn)

type
  Segment = tuple[start, len: BiggestInt]
  Counter = object
    top: BiggestInt                     # the highest number ever handed out
    owners: Table[string, seq[Segment]] # the numbers each module was handed
  Mine = object
    local: BiggestInt    # this process' view: the sum of its increments
    segs: seq[Segment]   # the numbers it may use, in order
    used: BiggestInt     # how many of them it did use

var
  held: File = nil # the lock file, while this process owns the counters
  owner = ""
  counters = initTable[string, Counter]()
  mine = initTable[string, Mine]()

proc counterFile(conf: ConfigRef): string =
  getNimcacheDir(conf).string / "ic.counters"

proc load(content: string) =
  # `t <top> <key>` starts a counter, `o <owner> <start> <len>...` follow it
  var key = ""
  for line in content.splitLines:
    let parts = line.split(' ')
    if parts.len >= 3 and parts[0] == "t":
      key = unescape(parts[2])
      counters[key] = Counter(top: parseBiggestInt(parts[1]))
    elif parts.len >= 2 and parts[0] == "o" and key.len > 0:
      var segs: seq[Segment] = @[]
      var i = 2
      while i+1 < parts.len:
        segs.add (parseBiggestInt(parts[i]), parseBiggestInt(parts[i+1]))
        inc i, 2
      counters[key].owners[unescape(parts[1])] = segs

proc render(): string =
  result = ""
  for key, c in counters:
    result.add "t " & $c.top & " " & escape(key) & "\n"
    for o, segs in c.owners:
      if segs.len == 0: continue
      result.add "o " & escape(o)
      for s in segs: result.add " " & $s.start & " " & $s.len
      result.add '\n'

proc store(conf: ConfigRef) =
  # Write-then-rename: a process killed mid-write must not corrupt the file
  # for every later build.
  let path = counterFile(conf)
  writeFile(path & ".tmp", render())
  moveFile(path & ".tmp", path)

proc usesSharedCounters*(conf: ConfigRef): bool {.inline.} =
  ## Under `nim m` each module is compiled by its own process, so the counters
  ## must be shared through the nimcache.
  conf.cmd == cmdM and not conf.ideActive

proc acquire(conf: ConfigRef) =
  if held != nil: return
  let path = counterFile(conf)
  createDir(parentDir(path))
  if not open(held, path & ".lock", fmAppend):
    raise newException(IOError, "cannot open " & path & ".lock")
  lockExclusive(held)
  owner = conf.projectFull.string
  if fileExists(path): load(readFile(path))

proc mineFor(key: string): Mine =
  if key in mine: result = mine[key]
  elif key in counters: result = Mine(segs: counters[key].owners.getOrDefault(owner))
  else: result = Mine()

proc nth(m: Mine; n: BiggestInt): BiggestInt =
  # the `n`-th number (1-based) of `m.segs`, which must hold that many
  var n = n
  for s in m.segs:
    if n <= s.len: return s.start + n - 1
    n -= s.len
  raiseAssert "counter segment underflow"

proc sharedCounterValue*(conf: ConfigRef; key: string): BiggestInt =
  acquire(conf)
  let m = mineFor(key)
  if m.local >= 1: result = nth(m, m.local)
  elif m.segs.len > 0: result = m.segs[0].start - 1 + m.local
  else: result = counters.getOrDefault(key).top + m.local

proc sharedCounterInc*(conf: ConfigRef; key: string; by: BiggestInt) =
  acquire(conf)
  var m = mineFor(key)
  m.local += by
  if m.local > m.used:
    var have = BiggestInt 0
    for s in m.segs: have += s.len
    var c = counters.getOrDefault(key)
    if m.local > have:
      # more numbers than last time: take fresh ones above the high-water mark
      let need = m.local - have
      if m.segs.len > 0 and m.segs[^1].start + m.segs[^1].len == c.top + 1:
        m.segs[^1].len += need
      else:
        m.segs.add (c.top + 1, need)
      c.top += need
    m.used = m.local
    # Record exactly the numbers used so far; unused ones from the previous
    # build are dropped and never handed to anybody else.
    var keep: seq[Segment] = @[]
    var n = m.used
    for s in m.segs:
      if n <= 0: break
      keep.add (s.start, min(s.len, n))
      n -= s.len
    c.owners[owner] = keep
    counters[key] = c
    mine[key] = m
    store(conf)
  else:
    mine[key] = m

proc releaseSharedCounters*() =
  ## The OS would release the lock at process exit too; this merely does it
  ## as early as possible.
  if held != nil:
    unlock(held)
    close(held)
    held = nil
