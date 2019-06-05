#
#
#            Nim's Runtime Library
#        (c) Copyright 2018 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module provides an API for macros that need to collect compile
## time information across module boundaries in global variables.
## Starting with version 0.19 of Nim this is not directly supported anymore
## as it breaks incremental compilations.
## Instead the API here needs to be used. See XXX (wikipedia page) for a
## theoretical foundation behind this.

type
  CacheSeq* = distinct string
  CacheTable* = distinct string
  CacheCounter* = distinct string

proc value*(c: CacheCounter): int {.magic: "NccValue".}
proc inc*(c: CacheCounter; by = 1) {.magic: "NccInc".}

proc add*(s: CacheSeq; value: NimNode) {.magic: "NcsAdd".}
proc incl*(s: CacheSeq; value: NimNode) {.magic: "NcsIncl".}
proc len*(s: CacheSeq): int {.magic: "NcsLen".}
proc `[]`*(s: CacheSeq; i: int): NimNode {.magic: "NcsAt".}
proc pop*(s: CacheSeq): NimNode {.magic: "NcsPop".}

iterator items*(s: CacheSeq): NimNode =
  for i in 0 ..< len(s): yield s[i]

proc find*(a: CacheSeq, item: NimNode): int {.inline.}=
  ## Returns the first index of `item` in `a` or -1 if not found.
  for i in items(a):
    if i == item: return
    inc(result)
  result = -1

proc contains*(a: CacheSeq, item: NimNode): bool {.inline.}=
  return find(a, item) >= 0

proc `[]=`*(t: CacheTable; key: string, value: NimNode) {.magic: "NctPut".}
  ## 'key' has to be unique!

proc len*(t: CacheTable): int {.magic: "NctLen".}
proc `[]`*(t: CacheTable; key: string): NimNode {.magic: "NctGet".}
proc contains*(t: CacheTable; key: string): bool {.magic: "NctContains".}
proc hasKey*(t: CacheTable; key: string): bool {.magic: "NctContains".}

proc hasNext(t: CacheTable; iter: int): bool {.magic: "NctHasNext".}
proc next(t: CacheTable; iter: int): (string, NimNode, int) {.magic: "NctNext".}

iterator pairs*(t: CacheTable): (string, NimNode) =
  var h = 0
  while hasNext(t, h):
    let (a, b, h2) = next(t, h)
    yield (a, b)
    h = h2
