#
#
#            Nim's Runtime Library
#        (c) Copyright 2019 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Cell seqs for cyclebreaker and cyclicrefs_v2.

when not declared(ansi_c):
  import system/ansi_c

when not declared(PNimTypeV2):
  type
    TNimTypeV2* {.compilerproc.} = object
      destructor*: pointer
      size*: int
      align*: int16
      depth*: int16
      display*: ptr UncheckedArray[uint32]
      when defined(nimTypeNames) or defined(nimArcIds) or defined(nimOrcLeakDetector):
        name*: cstring
      traceImpl*: pointer
      typeInfoV1*: pointer
      flags*: int
      when defined(gcDestructors):
        when defined(cpp):
          vTable*: ptr UncheckedArray[pointer]
        else:
          vTable*: UncheckedArray[pointer]
    PNimTypeV2* = ptr TNimTypeV2

type
  CellTuple[T] = (T, PNimTypeV2)
  CellArray[T] = ptr UncheckedArray[CellTuple[T]]
  CellSeq[T] = object
    len, cap: int
    d: CellArray[T]

proc resize[T](s: var CellSeq[T]) =
  s.cap = s.cap div 2 +% s.cap
  if s.cap < 4:
    s.cap = 4
  let newSize = cast[csize_t](s.cap *% sizeof(CellTuple[T]))
  if s.d == nil:
    s.d = cast[CellArray[T]](c_malloc(newSize))
  else:
    s.d = cast[CellArray[T]](c_realloc(s.d, newSize))

proc add[T](s: var CellSeq[T], c: T, t: PNimTypeV2) {.inline.} =
  if s.len >= s.cap:
    s.resize()
  s.d[s.len] = (c, t)
  s.len = s.len +% 1

proc init[T](s: var CellSeq[T], cap: int = 1024) =
  s.len = 0
  s.cap = max(4, cap)
  s.d = cast[CellArray[T]](c_malloc(cast[csize_t](s.cap *% sizeof(CellTuple[T]))))

proc deinit[T](s: var CellSeq[T]) =
  if s.d != nil:
    c_free(s.d)
    s.d = nil
  s.len = 0
  s.cap = 0

proc pop[T](s: var CellSeq[T]): (T, PNimTypeV2) =
  let last = s.len -% 1
  s.len = last
  s.d[last]
