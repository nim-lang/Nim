#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


## Module that implements a fixed length array whose size
## is determined at runtime. Note: This is not ready for other people to use!
##
## Unstable API.

const
  ArrayPartSize = 10

type
  RtArray*[T] = object ##
    L: Natural
    spart: seq[T]
    apart: array[ArrayPartSize, T]

template usesSeqPart(x): untyped = x.L > ArrayPartSize

proc initRtArray*[T](len: Natural): RtArray[T] =
  result.L = len
  if usesSeqPart(result):
    newSeq(result.spart, len)

proc getRawData*[T](x: var RtArray[T]): ptr UncheckedArray[T] =
  if usesSeqPart(x): cast[ptr UncheckedArray[T]](addr(x.spart[0]))
  else: cast[ptr UncheckedArray[T]](addr(x.apart[0]))

#proc len*[T](x: RtArray[T]): int = x.L

