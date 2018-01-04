#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Default ref implementation used by Nim's core.

import allocators

type
  TracingGc = ptr object of Allocator

  GcHeader = object
    t: ptr TypeLayout

  GcFrame {.core.} = object
    prev: ptr GcFrame
    marker: proc (self: GcFrame; a: Allocator)

proc `=trace`[T](a: ref T) =
  if not marked(a):
    mark(a)
    `=trace`(a[])

proc linkGcFrame(f: ptr GcFrame) {.core.}
proc unlinkGcFrame() {.core.}

proc setGcFrame(f: ptr GcFrame) {.core.}

proc registerGlobal(p: pointer; t: ptr TypeLayout) {.core.}
proc unregisterGlobal(p: pointer; t: ptr TypeLayout) {.core.}

proc registerThreadvar(p: pointer; t: ptr TypeLayout) {.core.}
proc unregisterThreadvar(p: pointer; t: ptr TypeLayout) {.core.}

proc newImpl(t: ptr TypeLayout): pointer =
  let a = getCurrentAllocator()
  let r = cast[ptr GcHeader](a.alloc(a, t.size + sizeof(GcHeader), t.alignment))
  r.typ = t
  result = r +! sizeof(GcHeader)

template new*[T](x: var ref T) =
  x = newImpl(getTypeLayout(x))


when false:
  # implement these if your GC requires them:
  proc writeBarrierLocal() {.core.}
  proc writeBarrierGlobal() {.core.}

  proc writeBarrierGeneric() {.core.}
