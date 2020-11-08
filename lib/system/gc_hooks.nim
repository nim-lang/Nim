#
#
#            Nim's Runtime Library
#        (c) Copyright 2019 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Hooks for memory management. Can be used to implement custom garbage
## collectors etc.

type
  GlobalMarkerProc = proc () {.nimcall, benign, raises: [], tags: [].}
var
  globalMarkersLen: int
  globalMarkers: array[0..3499, GlobalMarkerProc]
  threadLocalMarkersLen: int
  threadLocalMarkers: array[0..3499, GlobalMarkerProc]

proc nimRegisterGlobalMarker(markerProc: GlobalMarkerProc) {.compilerproc.} =
  if globalMarkersLen <= high(globalMarkers):
    globalMarkers[globalMarkersLen] = markerProc
    inc globalMarkersLen
  else:
    cstderr.rawWrite("[GC] cannot register global variable; too many global variables")
    quit 1

proc nimRegisterThreadLocalMarker(markerProc: GlobalMarkerProc) {.compilerproc.} =
  if threadLocalMarkersLen <= high(threadLocalMarkers):
    threadLocalMarkers[threadLocalMarkersLen] = markerProc
    inc threadLocalMarkersLen
  else:
    cstderr.rawWrite("[GC] cannot register thread local variable; too many thread local variables")
    quit 1

proc traverseGlobals*() =
  for i in 0..globalMarkersLen-1:
    globalMarkers[i]()

proc traverseThreadLocals*() =
  for i in 0..threadLocalMarkersLen-1:
    threadLocalMarkers[i]()

var
  newObjHook*: proc (typ: PNimType, size: int): pointer {.nimcall, tags: [], raises: [], gcsafe.}
  traverseObjHook*: proc (p: pointer, op: int) {.nimcall, tags: [], raises: [], gcsafe.}

proc nimGCvisit(p: pointer, op: int) {.inl, compilerRtl.} =
  traverseObjHook(p, op)

proc newObj(typ: PNimType, size: int): pointer {.inl, compilerRtl.} =
  result = newObjHook(typ, size)
