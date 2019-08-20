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

proc getTypeLayout(t: typedesc): ptr TypeLayout {.magic: "getTypeLayout".}
