#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Default string implementation used by Nim's core.

import allocators

type
  string {.core, exportc: "NimStringV2".} = object
    len, cap: int
    data: ptr UncheckedArray[char]

const nimStrVersion {.core.} = 2

template frees(s) = dealloc(s.data, s.cap + 1)

proc `=destroy`(s: var string) =
  if s.data != nil:
    frees(s)
    s.data = nil
    s.len = 0
    s.cap = 0

proc `=sink`(a: var string, b: string) =
  # we hope this is optimized away for not yet alive objects:
  if a.data != nil and a.data != b.data:
    frees(a)
  a.len = b.len
  a.cap = b.cap
  a.data = b.data

proc `=`(a: var string; b: string) =
  if a.data != nil and a.data != b.data:
    frees(a)
    a.data = nil
  a.len = b.len
  a.cap = b.cap
  if b.data != nil:
    a.data = cast[type(a.data)](alloc(a.cap + 1))
    copyMem(a.data, b.data, a.cap+1)

proc resize(s: var string) =
  let old = s.cap
  if old == 0: s.cap = 8
  else: s.cap = (s.cap * 3) shr 1
  s.data = cast[type(s.data)](realloc(s.data, old + 1, s.cap + 1))

proc add*(s: var string; c: char) =
  if s.len >= s.cap: resize(s)
  s.data[s.len] = c
  s.data[s.len+1] = '\0'
  inc s.len

proc ensure(s: var string; newLen: int) =
  let old = s.cap
  if newLen >= old:
    s.cap = max((old * 3) shr 1, newLen)
    if s.cap > 0:
      s.data = cast[type(s.data)](realloc(s.data, old + 1, s.cap + 1))

proc add*(s: var string; y: string) =
  if y.len != 0:
    let newLen = s.len + y.len
    ensure(s, newLen)
    copyMem(addr s.data[len], y.data, y.data.len + 1)
    s.len = newLen

proc len*(s: string): int {.inline.} = s.len

proc newString*(len: int): string =
  result.len = len
  result.cap = len
  if len > 0:
    result.data = alloc0(len+1)

converter toCString(x: string): cstring {.core, inline.} =
  if x.len == 0: cstring"" else: cast[cstring](x.data)

proc newStringOfCap*(cap: int): string =
  result.len = 0
  result.cap = cap
  if cap > 0:
    result.data = alloc(cap+1)

proc `&`*(a, b: string): string =
  let sum = a.len + b.len
  result = newStringOfCap(sum)
  result.len = sum
  copyMem(addr result.data[0], a.data, a.len)
  copyMem(addr result.data[a.len], b.data, b.len)
  if sum > 0:
    result.data[sum] = '\0'

proc concat(x: openArray[string]): string {.core.} =
  ## used be the code generator to optimize 'x & y & z ...'
  var sum = 0
  for i in 0 ..< x.len: inc(sum, x[i].len)
  result = newStringOfCap(sum)
  sum = 0
  for i in 0 ..< x.len:
    let L = x[i].len
    copyMem(addr result.data[sum], x[i].data, L)
    inc(sum, L)

