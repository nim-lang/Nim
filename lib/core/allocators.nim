#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

type
  AllocatorFlag* {.pure.} = enum  ## flags describing the properties of the allocator
    ThreadLocal ## the allocator is thread local only.
    ZerosMem    ## the allocator always zeros the memory on an allocation
  Allocator* = ptr AllocatorObj
  AllocatorObj* {.inheritable, compilerproc.} = object
    alloc*: proc (a: Allocator; size: int; alignment: int = 8): pointer {.nimcall, raises: [], tags: [].}
    dealloc*: proc (a: Allocator; p: pointer; size: int) {.nimcall, raises: [], tags: [].}
    realloc*: proc (a: Allocator; p: pointer; oldSize, newSize: int): pointer {.nimcall, raises: [], tags: [].}
    deallocAll*: proc (a: Allocator) {.nimcall, raises: [], tags: [].}
    flags*: set[AllocatorFlag]
    name*: cstring
    allocCount: int
    deallocCount: int

var
  localAllocator {.threadvar.}: Allocator
  sharedAllocator: Allocator
  allocatorStorage {.threadvar.}: AllocatorObj

proc getLocalAllocator*(): Allocator =
  result = localAllocator
  if result == nil:
    result = addr allocatorStorage
    result.alloc = proc (a: Allocator; size: int; alignment: int = 8): pointer {.nimcall, raises: [].} =
      result = system.alloc(size)
      inc a.allocCount
    result.dealloc = proc (a: Allocator; p: pointer; size: int) {.nimcall, raises: [].} =
      system.dealloc(p)
      inc a.deallocCount
    result.realloc = proc (a: Allocator; p: pointer; oldSize, newSize: int): pointer {.nimcall, raises: [].} =
      result = system.realloc(p, newSize)
    result.deallocAll = nil
    result.flags = {ThreadLocal}
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
