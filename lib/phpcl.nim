#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## PHP compatibility layer.

type
  PhpArray*[Key, Val] = ref object

  PhpObj* = ref object ## can be a string, an int etc.

proc explode*(sep, x: string): seq[string] {.importc: "explode".}
template split*(x, sep: string): seq[string] = explode(sep, x)

proc `$`*(x: PhpObj): string {.importcpp: "(#)".}
proc `++`*(x: PhpObj) {.importcpp: "++(#)".}

proc `==`*(x, y: PhpObj): string {.importcpp: "((#) == (#))".}
proc `<=`*(x, y: PhpObj): string {.importcpp: "((#) <= (#))".}
proc `<`*(x, y: PhpObj): string {.importcpp: "((#) < (#))".}

proc toUpper*(x: string): string {.importc: "strtoupper".}
proc toLower*(x: string): string {.importc: "strtolower".}

proc strtr*(s: string, replacePairs: PhpArray[string, string]): string {.importc.}
proc strtr*(s, fromm, to: string): string {.importc.}

proc toArray*[K,V](pairs: openarray[(K,V)]): PhpArray[K,V] {.magic:
  "Array".}
template strtr*(s: string, replacePairs: openarray[(string, string)]): string =
  strtr(toArray(replacePairs))

iterator pairs*[K,V](d: PhpArray[K,V]): (K,V) =
  var k: K
  var v: V
  {.emit: "foreach (`d` as `k`=>`v`) {".}
  yield (k, v)
  {.emit: "}".}

proc `[]`*[K,V](d: PhpArray[K,V]; k: K): V {.importcpp: "#[#]".}
proc `[]=`*[K,V](d: PhpArray[K,V]; k: K; v: V) {.importcpp: "#[#] = #".}

proc ksort*[K,V](d: PhpArray[K,V]) {.importc.}
proc krsort*[K,V](d: PhpArray[K,V]) {.importc.}
proc keys*[K,V](d: PhpArray[K,V]): seq[K] {.importc.}
