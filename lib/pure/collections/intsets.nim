#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Specialization of the generic `packedsets module <packedsets.html>`_
## (see its documentation for more examples) for ordinal sparse sets.

import std/private/since
import std/packedsets
export packedsets

type
  IntSet* = PackedSet[int]

proc toIntSet*(x: openArray[int]): IntSet {.since: (1, 3), inline.} = toPackedSet[int](x)

proc initIntSet*(): IntSet {.inline.} = initPackedSet[int]()

