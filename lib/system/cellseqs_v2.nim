#
#
#            Nim's Runtime Library
#        (c) Copyright 2019 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Cell seqs for cyclebreaker and cyclicrefs_v2.

type
  CellTuple[T] = (T, PNimTypeV2)
  CellArray[T] = ptr UncheckedArray[CellTuple[T]]
  CellSeq[T] = object
    len, cap: int
    d: CellArray[T]

proc resize[T](s: var CellSeq[T]) =
  s.cap = s.cap div 2 +% s.cap
  let newSize = s.cap *% sizeof(CellTuple[T])
  when compileOption("threads"):
    s.d = cast[CellArray[T]](reallocShared(s.d, cast[Natural](newSize)))
  else:
    s.d = cast[CellArray[T]](realloc(s.d, cast[Natural](newSize)))

proc add[T](s: var CellSeq[T], c: T, t: PNimTypeV2) {.inline.} =
  if s.len >= s.cap:
    s.resize()
  s.d[s.len] = (c, t)
  s.len = s.len +% 1

proc init[T](s: var CellSeq[T], cap: int = 1024) =
  s.len = 0
  s.cap = cap
  when compileOption("threads"):
    s.d = cast[CellArray[T]](allocShared(cast[Natural](s.cap *% sizeof(CellTuple[T]))))
  else:
    s.d = cast[CellArray[T]](alloc(cast[Natural](s.cap *% sizeof(CellTuple[T]))))

proc deinit[T](s: var CellSeq[T]) =
  if s.d != nil:
    when compileOption("threads"):
      deallocShared(s.d)
    else:
      dealloc(s.d)
    s.d = nil
  s.len = 0
  s.cap = 0

proc pop[T](s: var CellSeq[T]): (T, PNimTypeV2) =
  let last = s.len -% 1
  s.len = last
  s.d[last]
