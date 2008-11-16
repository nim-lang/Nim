#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2006 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# 64 bit integers for platforms that don't have those

type
  IInt64 = tuple[lo, hi: int32]

proc cmpI64(x, y: IInt64): int32 {.compilerproc.} =
  result = x.hi -% y.hi
  if result == 0: result = x.lo -% y.lo

proc addI64(x, y: IInt64): IInt64 {.compilerproc.} =
  result = x
  result.lo = result.lo +% y.lo
  result.hi = result.hi +% y.hi
  if y.lo > 0 and result.lo < y.lo:
    inc(result.hi)
  elif y.lo < 0 and result.lo > y.lo:
    dec(result.hi)

proc subI64(x, y: IInt64): IInt64 {.compilerproc.} =
  result = x
  result.lo = result.lo -% y.lo
  result.hi = result.hi -% y.hi
  if y.lo > 0 and result.lo < y.lo:
    inc(result.hi)
  elif y.lo < 0 and result.lo > y.lo:
    dec(result.hi)

proc mulI64(x, y: IInt64): IInt64 {.compilerproc.} =
  result.lo = x.lo *% y.lo
  result.hi = y.hi *% y.hi
  if y.lo > 0 and result.lo < y.lo:
    inc(result.hi)
  elif y.lo < 0 and result.lo > y.lo:
    dec(result.hi)

proc divI64(x, y: IInt64): IInt64 {.compilerproc.} =
  # XXX: to implement

proc modI64(x, y: IInt64): IInt64 {.compilerproc.} =
  # XXX: to implement

proc bitandI64(x, y: IInt64): IInt64 {.compilerproc.} =
  result.hi = x.hi and y.hi
  result.lo = x.lo and y.lo

proc bitorI64(x, y: IInt64): IInt64 {.compilerproc.} =
  result.hi = x.hi or y.hi
  result.lo = x.lo or y.lo

proc bitxorI64(x, y: IInt64): IInt64 {.compilerproc.} =
  result.hi = x.hi xor y.hi
  result.lo = x.lo xor y.lo

proc bitnotI64(x: IInt64): IInt64 {.compilerproc.} =
  result.lo = not x.lo
  result.hi = not x.hi

proc shlI64(x, y: IInt64): IInt64 {.compilerproc.} =
  # XXX: to implement

proc shrI64(x, y: IInt64): IInt64 {.compilerproc.} =
  # XXX: to implement
