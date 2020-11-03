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
  CellTuple = (PT, PNimTypeV2)
  CellArray = ptr UncheckedArray[CellTuple]
  CellSeq = object
    len, cap: int
    d: CellArray

proc add(s: var CellSeq, c: PT; t: PNimTypeV2) {.inline.} =
  if s.len >= s.cap:
    s.cap = s.cap * 3 div 2
    when compileOption("threads"):
      var d = cast[CellArray](allocShared(uint(s.cap * sizeof(CellTuple))))
    else:
      var d = cast[CellArray](alloc(s.cap * sizeof(CellTuple)))
    copyMem(d, s.d, s.len * sizeof(CellTuple))
    when compileOption("threads"):
      deallocShared(s.d)
    else:
      dealloc(s.d)
    s.d = d
    # XXX: realloc?
  s.d[s.len] = (c, t)
  inc(s.len)

proc init(s: var CellSeq, cap: int = 1024) =
  s.len = 0
  s.cap = cap
  when compileOption("threads"):
    s.d = cast[CellArray](allocShared(uint(s.cap * sizeof(CellTuple))))
  else:
    s.d = cast[CellArray](alloc(s.cap * sizeof(CellTuple)))

proc deinit(s: var CellSeq) =
  if s.d != nil:
    when compileOption("threads"):
      deallocShared(s.d)
    else:
      dealloc(s.d)
    s.d = nil
  s.len = 0
  s.cap = 0

proc pop(s: var CellSeq): (PT, PNimTypeV2) =
  result = s.d[s.len-1]
  dec s.len
