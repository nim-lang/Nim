#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Deprecated by the generic `OrdSet` for ordinal sparse sets.
## **See also:**
## * `ordinal sets module <ordsets.html>`_ for more general int sets

import std/private/since
import std/ordsets
export ordsets

type
  IntSet* = OrdSet[int]

proc toIntSet*(x: openArray[int]): IntSet {.since: (1, 3), inline.} = toOrdSet[int](x)

proc initIntSet*(): IntSet {.inline.} = initOrdSet[int]()

