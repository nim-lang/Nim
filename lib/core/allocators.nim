#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

type
  TypeLayout* = object
    size*, alignment*: int
    destructor*: proc (self: pointer; a: Allocator) {.nimcall.}
    trace*: proc (self: pointer; a: Allocator) {.nimcall.}
    when false:
      construct*: proc (self: pointer; a: Allocator) {.nimcall.}
      copy*, deepcopy*, sink*: proc (self, other: pointer; a: Allocator) {.nimcall.}

  Allocator* {.inheritable.} = ptr object
    alloc*: proc (a: Allocator; size: int; alignment = 8): pointer {.nimcall.}
    dealloc*: proc (a: Allocator; p: pointer; size: int) {.nimcall.}
    realloc*: proc (a: Allocator; p: pointer; oldSize, newSize: int): pointer {.nimcall.}
    visit*: proc (fieldAddr: ptr pointer; a: Allocator) {.nimcall.}

#proc allocArray(a: Allocator; L, elem: TypeLayout; n: int): pointer
#proc deallocArray(a: Allocator; p: pointer; L, elem: TypeLayout; n: int)

proc getTypeLayout*(t: typedesc): ptr TypeLayout {.magic: "getTypeLayout".}

var
  currentAllocator {.threadvar.}: Allocator

proc getCurrentAllocator*(): Allocator =
  result = currentAllocator

proc setCurrentAllocator*(a: Allocator) =
  currentAllocator = a

proc alloc*(size: int): pointer =
  let a = getCurrentAllocator()
  result = a.alloc(a, size)

proc dealloc*(p: pointer; size: int) =
  let a = getCurrentAllocator()
  a.dealloc(a, size)

proc realloc*(p: pointer; oldSize, newSize: int): pointer =
  let a = getCurrentAllocator()
  result = a.realloc(a, oldSize, newSize)
