#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

type
  Allocator* {.inheritable.} = ptr object
    alloc*: proc (size: int; alignment: int): pointer {.nimcall.}
    dealloc*: proc (p: pointer; size: int) {.nimcall.}
    realloc*: proc (p: pointer; oldSize, newSize: int): pointer {.nimcall.}

var
  currentAllocator {.threadvar.}: Allocator

proc getCurrentAllocator*(): Allocator =
  result = currentAllocator

proc setCurrentAllocator*(a: Allocator) =
  currentAllocator = a

proc alloc*(size: int; alignment = 8): pointer =
  let a = getCurrentAllocator()
  result = a.alloc(size, alignment)

proc dealloc*(p: pointer; size: int) =
  let a = getCurrentAllocator()
  a.dealloc(p, size)

proc realloc*(p: pointer; oldSize, newSize: int): pointer =
  let a = getCurrentAllocator()
  result = a.realloc(p, oldSize, newSize)
