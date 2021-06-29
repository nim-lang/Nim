#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## :Authors: Zahary Karadjov
##
## This module provides utilities for reserving a portions of the
## address space of a program without consuming physical memory.
## It can be used to implement a dynamically resizable buffer that
## is guaranteed to remain in the same memory location. The buffer
## will be able to grow up to the size of the initially reserved
## portion of the address space.
##
## Unstable API.

from os import raiseOSError, osLastError

template distance*(lhs, rhs: pointer): int =
  cast[int](rhs) - cast[int](lhs)

template shift*(p: pointer, distance: int): pointer =
  cast[pointer](cast[int](p) + distance)

type
  MemAccessFlags* = int

  ReservedMem* = object
    memStart: pointer
    usedMemEnd: pointer
    committedMemEnd: pointer
    memEnd: pointer
    maxCommittedAndUnusedPages: int
    accessFlags: MemAccessFlags

  ReservedMemSeq*[T] = object
    mem: ReservedMem

when defined(windows):
  import winlean

  type
    SYSTEM_INFO {.final, pure.} = object
      u1: uint32
      dwPageSize: uint32
      lpMinimumApplicationAddress: pointer
      lpMaximumApplicationAddress: pointer
      dwActiveProcessorMask: ptr uint32
      dwNumberOfProcessors: uint32
      dwProcessorType: uint32
      dwAllocationGranularity: uint32
      wProcessorLevel: uint16
      wProcessorRevision: uint16

  proc getSystemInfo(lpSystemInfo: ptr SYSTEM_INFO) {.stdcall,
      dynlib: "kernel32", importc: "GetSystemInfo".}

  proc getAllocationGranularity: uint =
    var sysInfo: SYSTEM_INFO
    getSystemInfo(addr sysInfo)
    return uint(sysInfo.dwAllocationGranularity)

  let allocationGranularity = getAllocationGranularity().int

  const
    memNoAccess = MemAccessFlags(PAGE_NOACCESS)
    memExec* = MemAccessFlags(PAGE_EXECUTE)
    memExecRead* = MemAccessFlags(PAGE_EXECUTE_READ)
    memExecReadWrite* = MemAccessFlags(PAGE_EXECUTE_READWRITE)
    memRead* = MemAccessFlags(PAGE_READONLY)
    memReadWrite* = MemAccessFlags(PAGE_READWRITE)

  template check(expr) =
    let r = expr
    if r == cast[typeof(r)](0):
      raiseOSError(osLastError())

else:
  import posix

  let allocationGranularity = sysconf(SC_PAGESIZE)

  let
    memNoAccess = MemAccessFlags(PROT_NONE)
    memExec* = MemAccessFlags(PROT_EXEC)
    memExecRead* = MemAccessFlags(PROT_EXEC or PROT_READ)
    memExecReadWrite* = MemAccessFlags(PROT_EXEC or PROT_READ or PROT_WRITE)
    memRead* = MemAccessFlags(PROT_READ)
    memReadWrite* = MemAccessFlags(PROT_READ or PROT_WRITE)

  template check(expr) =
    if not expr:
      raiseOSError(osLastError())

func nextAlignedOffset(n, alignment: int): int =
  result = n
  let m = n mod alignment
  if m != 0: result += alignment - m


when defined(windows):
  const
    MEM_DECOMMIT = 0x4000
    MEM_RESERVE = 0x2000
    MEM_COMMIT = 0x1000
  proc virtualFree(lpAddress: pointer, dwSize: int,
                   dwFreeType: int32): cint {.header: "<windows.h>", stdcall,
                   importc: "VirtualFree".}
  proc virtualAlloc(lpAddress: pointer, dwSize: int, flAllocationType,
                    flProtect: int32): pointer {.
                    header: "<windows.h>", stdcall, importc: "VirtualAlloc".}

proc init*(T: type ReservedMem,
           maxLen: Natural,
           initLen: Natural = 0,
           initCommitLen = initLen,
           memStart = pointer(nil),
           accessFlags = memReadWrite,
           maxCommittedAndUnusedPages = 3): ReservedMem =

  assert initLen <= initCommitLen
  let commitSize = nextAlignedOffset(initCommitLen, allocationGranularity)

  when defined(windows):
    result.memStart = virtualAlloc(memStart, maxLen, MEM_RESERVE,
        accessFlags.cint)
    check result.memStart
    if commitSize > 0:
      check virtualAlloc(result.memStart, commitSize, MEM_COMMIT,
          accessFlags.cint)
  else:
    var allocFlags = MAP_PRIVATE or MAP_ANONYMOUS # or MAP_NORESERVE
                                                  # if memStart != nil:
                                                  #  allocFlags = allocFlags or MAP_FIXED_NOREPLACE
    result.memStart = mmap(memStart, maxLen, PROT_NONE, allocFlags, -1, 0)
    check result.memStart != MAP_FAILED
    if commitSize > 0:
      check mprotect(result.memStart, commitSize, cint(accessFlags)) == 0

  result.usedMemEnd = result.memStart.shift(initLen)
  result.committedMemEnd = result.memStart.shift(commitSize)
  result.memEnd = result.memStart.shift(maxLen)
  result.accessFlags = accessFlags
  result.maxCommittedAndUnusedPages = maxCommittedAndUnusedPages

func len*(m: ReservedMem): int =
  distance(m.memStart, m.usedMemEnd)

func commitedLen*(m: ReservedMem): int =
  distance(m.memStart, m.committedMemEnd)

func maxLen*(m: ReservedMem): int =
  distance(m.memStart, m.memEnd)

proc setLen*(m: var ReservedMem, newLen: int) =
  let len = m.len
  m.usedMemEnd = m.memStart.shift(newLen)
  if newLen > len:
    let d = distance(m.committedMemEnd, m.usedMemEnd)
    if d > 0:
      let commitExtensionSize = nextAlignedOffset(d, allocationGranularity)
      when defined(windows):
        check virtualAlloc(m.committedMemEnd, commitExtensionSize,
                           MEM_COMMIT, m.accessFlags.cint)
      else:
        check mprotect(m.committedMemEnd, commitExtensionSize,
            m.accessFlags.cint) == 0
  else:
    let d = distance(m.usedMemEnd, m.committedMemEnd) -
            m.maxCommittedAndUnusedPages * allocationGranularity
    if d > 0:
      let commitSizeShrinkage = nextAlignedOffset(d, allocationGranularity)
      let newCommitEnd = m.committedMemEnd.shift(-commitSizeShrinkage)

      when defined(windows):
        check virtualFree(newCommitEnd, commitSizeShrinkage, MEM_DECOMMIT)
      else:
        check posix_madvise(newCommitEnd, commitSizeShrinkage,
                            POSIX_MADV_DONTNEED) == 0

      m.committedMemEnd = newCommitEnd

proc init*(SeqType: type ReservedMemSeq,
           maxLen: Natural,
           initLen: Natural = 0,
           initCommitLen: Natural = 0,
           memStart = pointer(nil),
           accessFlags = memReadWrite,
           maxCommittedAndUnusedPages = 3): SeqType =

  let elemSize = sizeof(SeqType.T)
  result.mem = ReservedMem.init(maxLen * elemSize,
                                initLen * elemSize,
                                initCommitLen * elemSize,
                                memStart, accessFlags,
                                maxCommittedAndUnusedPages)

func `[]`*[T](s: ReservedMemSeq[T], pos: Natural): lent T =
  let elemAddr = s.mem.memStart.shift(pos * sizeof(T))
  rangeCheck elemAddr < s.mem.usedMemEnd
  result = (cast[ptr T](elemAddr))[]

func `[]`*[T](s: var ReservedMemSeq[T], pos: Natural): var T =
  let elemAddr = s.mem.memStart.shift(pos * sizeof(T))
  rangeCheck elemAddr < s.mem.usedMemEnd
  result = (cast[ptr T](elemAddr))[]

func `[]`*[T](s: ReservedMemSeq[T], rpos: BackwardsIndex): lent T =
  return s[int(s.len) - int(rpos)]

func `[]`*[T](s: var ReservedMemSeq[T], rpos: BackwardsIndex): var T =
  return s[int(s.len) - int(rpos)]

func len*[T](s: ReservedMemSeq[T]): int =
  s.mem.len div sizeof(T)

proc setLen*[T](s: var ReservedMemSeq[T], newLen: int) =
  # TODO call destructors
  s.mem.setLen(newLen * sizeof(T))

proc add*[T](s: var ReservedMemSeq[T], val: T) =
  let len = s.len
  s.setLen(len + 1)
  s[len] = val

proc pop*[T](s: var ReservedMemSeq[T]): T =
  assert s.usedMemEnd != s.memStart
  let lastIdx = s.len - 1
  result = s[lastIdx]
  s.setLen(lastIdx)

func commitedLen*[T](s: ReservedMemSeq[T]): int =
  s.mem.commitedLen div sizeof(T)

func maxLen*[T](s: ReservedMemSeq[T]): int =
  s.mem.maxLen div sizeof(T)

