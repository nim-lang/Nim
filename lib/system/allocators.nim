#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Unstable API.

type
  AllocatorFlag* {.pure.} = enum  ## flags describing the properties of the allocator
    ThreadLocal ## the allocator is thread local only.
    ZerosMem    ## the allocator always zeros the memory on an allocation
  Allocator* = ptr AllocatorObj
  AllocatorObj* {.inheritable, compilerproc.} = object
    alloc*: proc (a: Allocator; size: int; alignment: int = 8): pointer {.nimcall, raises: [], tags: [], gcsafe.}
    dealloc*: proc (a: Allocator; p: pointer; size: int) {.nimcall, raises: [], tags: [], gcsafe.}
    realloc*: proc (a: Allocator; p: pointer; oldSize, newSize: int): pointer {.nimcall, raises: [], tags: [], gcsafe.}
    deallocAll*: proc (a: Allocator) {.nimcall, raises: [], tags: [], gcsafe.}
    flags*: set[AllocatorFlag]
    name*: cstring
    allocCount: int
    deallocCount: int

var
  localAllocator {.threadvar.}: Allocator
  sharedAllocator: Allocator
  allocatorStorage {.threadvar.}: AllocatorObj

when defined(useMalloc) and not defined(nimscript):
  import "system/ansi_c"

import "system/memory"

template `+!`(p: pointer, s: int): pointer =
  cast[pointer](cast[int](p) +% s)

proc getLocalAllocator*(): Allocator =
  result = localAllocator
  if result == nil:
    result = addr allocatorStorage
    result.alloc = proc (a: Allocator; size: int; alignment: int = 8): pointer {.nimcall, raises: [].} =
      when defined(useMalloc) and not defined(nimscript):
        result = c_malloc(cuint size)
        # XXX do we need this?
        nimZeroMem(result, size)
      elif compileOption("threads"):
        result = system.allocShared0(size)
      else:
        result = system.alloc0(size)
      inc a.allocCount
    result.dealloc = proc (a: Allocator; p: pointer; size: int) {.nimcall, raises: [].} =
      when defined(useMalloc) and not defined(nimscript):
        c_free(p)
      elif compileOption("threads"):
        system.deallocShared(p)
      else:
        system.dealloc(p)
      inc a.deallocCount
    result.realloc = proc (a: Allocator; p: pointer; oldSize, newSize: int): pointer {.nimcall, raises: [].} =
      when defined(useMalloc) and not defined(nimscript):
        result = c_realloc(p, cuint newSize)
      elif compileOption("threads"):
        result = system.reallocShared(p, newSize)
      else:
        result = system.realloc(p, newSize)
      nimZeroMem(result +! oldSize, newSize - oldSize)
    result.deallocAll = nil
    result.flags = {ThreadLocal, ZerosMem}
    result.name = "nim_local"
    localAllocator = result

proc setLocalAllocator*(a: Allocator) =
  localAllocator = a

proc getSharedAllocator*(): Allocator =
  result = sharedAllocator

proc setSharedAllocator*(a: Allocator) =
  sharedAllocator = a

proc allocCounters*(): (int, int) =
  let a = getLocalAllocator()
  result = (a.allocCount, a.deallocCount)
