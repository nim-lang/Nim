#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

type
  Allocator* = ptr object {.inheritable.}
    alloc*: proc (a: Allocator; size: int; alignment: int = 8): pointer {.nimcall.}
    dealloc*: proc (a: Allocator; p: pointer; size: int) {.nimcall.}
    realloc*: proc (a: Allocator; p: pointer; oldSize, newSize: int): pointer {.nimcall.}

var
  currentAllocator {.threadvar.}: Allocator

proc getCurrentAllocator*(): Allocator =
  result = currentAllocator

proc setCurrentAllocator*(a: Allocator) =
  currentAllocator = a

proc alloc*(size: int; alignment: int = 8): pointer =
  let a = getCurrentAllocator()
  result = a.alloc(a, size, alignment)

proc dealloc*(p: pointer; size: int) =
  let a = getCurrentAllocator()
  a.dealloc(a, p, size)

proc realloc*(p: pointer; oldSize, newSize: int): pointer =
  let a = getCurrentAllocator()
  result = a.realloc(a, p, oldSize, newSize)
