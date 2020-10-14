#
#
#            Nim's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains support for a `rope`:idx: data type.
## Ropes can represent very long strings efficiently; especially concatenation
## is done in O(1) instead of O(n). They are essentially concatenation
## trees that are only flattened when converting to a native Nim
## string. The empty string is represented by ``nil``. Ropes are immutable and
## subtrees can be shared without copying.
## Leaves can be cached for better memory efficiency at the cost of
## runtime efficiency.

include "system/inclrtl"
import streams

{.push debugger: off.} # the user does not want to trace a part
                       # of the standard library!

const
  countCacheMisses = false

var
  cacheEnabled = false

type
  Rope* = ref RopeObj ## empty rope is represented by nil
  RopeObj {.acyclic.} = object
    left, right: Rope
    length: int
    data: string # != nil if a leaf

# Note that the left and right pointers are not needed for leafs.
# Leaves have relatively high memory overhead (~30 bytes on a 32
# bit machine) and we produce many of them. This is why we cache and
# share leafs across different rope trees.
# To cache them they are inserted in another tree, a splay tree for best
# performance. But for the caching tree we use the leaf's left and right
# pointers.

proc len*(a: Rope): int {.rtl, extern: "nro$1".} =
  ## the rope's length
  if a == nil: result = 0
  else: result = a.length

proc newRope(): Rope = new(result)
proc newRope(data: string): Rope =
  new(result)
  result.length = len(data)
  result.data = data

var
  cache {.threadvar.}: Rope # the root of the cache tree
  N {.threadvar.}: Rope     # dummy rope needed for splay algorithm

when countCacheMisses:
  var misses, hits: int

proc splay(s: string, tree: Rope, cmpres: var int): Rope =
  var c: int
  var t = tree
  N.left = nil
  N.right = nil # reset to nil
  var le = N
  var r = N
  while true:
    c = cmp(s, t.data)
    if c < 0:
      if (t.left != nil) and (s < t.left.data):
        var y = t.left
        t.left = y.right
        y.right = t
        t = y
      if t.left == nil: break
      r.left = t
      r = t
      t = t.left
    elif c > 0:
      if (t.right != nil) and (s > t.right.data):
        var y = t.right
        t.right = y.left
        y.left = t
        t = y
      if t.right == nil: break
      le.right = t
      le = t
      t = t.right
    else:
      break
  cmpres = c
  le.right = t.left
  r.left = t.right
  t.left = N.right
  t.right = N.left
  result = t

proc insertInCache(s: string, tree: Rope): Rope =
  var t = tree
  if t == nil:
    result = newRope(s)
    when countCacheMisses: inc(misses)
    return
  var cmp: int
  t = splay(s, t, cmp)
  if cmp == 0:
    # We get here if it's already in the Tree
    # Don't add it again
    result = t
    when countCacheMisses: inc(hits)
  else:
    when countCacheMisses: inc(misses)
    result = newRope(s)
    if cmp < 0:
      result.left = t.left
      result.right = t
      t.left = nil
    else:
      # i > t.item:
      result.right = t.right
      result.left = t
      t.right = nil

proc rope*(s: string = ""): Rope {.rtl, extern: "nro$1Str".} =
  ## Converts a string to a rope.
  if s.len == 0:
    result = nil
  else:
    when nimvm:
      # No caching in VM context
      result = newRope(s)
    else:
      if cacheEnabled:
        result = insertInCache(s, cache)
        cache = result
      else:
        result = newRope(s)

proc rope*(i: BiggestInt): Rope {.rtl, extern: "nro$1BiggestInt".} =
  ## Converts an int to a rope.
  result = rope($i)

proc rope*(f: BiggestFloat): Rope {.rtl, extern: "nro$1BiggestFloat".} =
  ## Converts a float to a rope.
  result = rope($f)

proc enableCache*() {.rtl, extern: "nro$1".} =
  ## Enables the caching of leaves. This reduces the memory footprint at
  ## the cost of runtime efficiency.
  cacheEnabled = true

proc disableCache*() {.rtl, extern: "nro$1".} =
  ## the cache is discarded and disabled. The GC will reuse its used memory.
  cache = nil
  cacheEnabled = false

proc `&`*(a, b: Rope): Rope {.rtl, extern: "nroConcRopeRope".} =
  ## the concatenation operator for ropes.
  if a == nil:
    result = b
  elif b == nil:
    result = a
  else:
    result = newRope()
    result.length = a.length + b.length
    result.left = a
    result.right = b

proc `&`*(a: Rope, b: string): Rope {.rtl, extern: "nroConcRopeStr".} =
  ## the concatenation operator for ropes.
  result = a & rope(b)

proc `&`*(a: string, b: Rope): Rope {.rtl, extern: "nroConcStrRope".} =
  ## the concatenation operator for ropes.
  result = rope(a) & b

proc `&`*(a: openArray[Rope]): Rope {.rtl, extern: "nroConcOpenArray".} =
  ## the concatenation operator for an openarray of ropes.
  for i in countup(0, high(a)): result = result & a[i]

proc add*(a: var Rope, b: Rope) {.rtl, extern: "nro$1Rope".} =
  ## adds `b` to the rope `a`.
  a = a & b

proc add*(a: var Rope, b: string) {.rtl, extern: "nro$1Str".} =
  ## adds `b` to the rope `a`.
  a = a & b

proc `[]`*(r: Rope, i: int): char {.rtl, extern: "nroCharAt".} =
  ## returns the character at position `i` in the rope `r`. This is quite
  ## expensive! Worst-case: O(n). If ``i >= r.len``, ``\0`` is returned.
  var x = r
  var j = i
  if x == nil: return
  while true:
    if x != nil and x.data.len > 0:
      if j < x.data.len: return x.data[j]
      return '\0'
    else:
      if x.left.length > j:
        x = x.left
      else:
        x = x.right
        dec(j, x.len)

iterator leaves*(r: Rope): string =
  ## iterates over any leaf string in the rope `r`.
  if r != nil:
    var stack = @[r]
    while stack.len > 0:
      var it = stack.pop
      while it.left != nil:
        assert(it.right != nil)
        stack.add(it.right)
        it = it.left
        assert(it != nil)
      yield it.data

iterator items*(r: Rope): char =
  ## iterates over any character in the rope `r`.
  for s in leaves(r):
    for c in items(s): yield c

proc write*(f: File, r: Rope) {.rtl, extern: "nro$1".} =
  ## writes a rope to a file.
  for s in leaves(r): write(f, s)

proc write*(s: Stream, r: Rope) {.rtl, extern: "nroWriteStream".} =
  ## writes a rope to a stream.
  for rs in leaves(r): write(s, rs)

proc `$`*(r: Rope): string {.rtl, extern: "nroToString".} =
  ## converts a rope back to a string.
  result = newStringOfCap(r.len)
  for s in leaves(r): add(result, s)

proc `%`*(frmt: string, args: openArray[Rope]): Rope {.
  rtl, extern: "nroFormat".} =
  ## `%` substitution operator for ropes. Does not support the ``$identifier``
  ## nor ``${identifier}`` notations.
  var i = 0
  var length = len(frmt)
  result = nil
  var num = 0
  while i < length:
    if frmt[i] == '$':
      inc(i)
      case frmt[i]
      of '$':
        add(result, "$")
        inc(i)
      of '#':
        inc(i)
        add(result, args[num])
        inc(num)
      of '0'..'9':
        var j = 0
        while true:
          j = j * 10 + ord(frmt[i]) - ord('0')
          inc(i)
          if frmt[i] notin {'0'..'9'}: break
        add(result, args[j-1])
      of '{':
        inc(i)
        var j = 0
        while frmt[i] in {'0'..'9'}:
          j = j * 10 + ord(frmt[i]) - ord('0')
          inc(i)
        if frmt[i] == '}': inc(i)
        else: raise newException(ValueError, "invalid format string")

        add(result, args[j-1])
      else: raise newException(ValueError, "invalid format string")
    var start = i
    while i < length:
      if frmt[i] != '$': inc(i)
      else: break
    if i - 1 >= start:
      add(result, substr(frmt, start, i - 1))

proc addf*(c: var Rope, frmt: string, args: openArray[Rope]) {.
  rtl, extern: "nro$1".} =
  ## shortcut for ``add(c, frmt % args)``.
  add(c, frmt % args)

when not defined(js) and not defined(nimscript):
  const
    bufSize = 1024 # 1 KB is reasonable

  proc equalsFile*(r: Rope, f: File): bool {.rtl, extern: "nro$1File".} =
    ## returns true if the contents of the file `f` equal `r`.
    var
      buf: array[bufSize, char]
      bpos = buf.len
      blen = buf.len

    for s in leaves(r):
      var spos = 0
      let slen = s.len
      while spos < slen:
        if bpos == blen:
          # Read more data
          bpos = 0
          blen = readBuffer(f, addr(buf[0]), buf.len)
          if blen == 0: # no more data in file
            result = false
            return
        let n = min(blen - bpos, slen - spos)
        # TODO There's gotta be a better way of comparing here...
        if not equalMem(addr(buf[bpos]),
                        cast[pointer](cast[int](cstring(s))+spos), n):
          result = false
          return
        spos += n
        bpos += n

    result = readBuffer(f, addr(buf[0]), 1) == 0 # check that we've read all

  proc equalsFile*(r: Rope, filename: string): bool {.rtl, extern: "nro$1Str".} =
    ## returns true if the contents of the file `f` equal `r`. If `f` does not
    ## exist, false is returned.
    var f: File
    result = open(f, filename)
    if result:
      result = equalsFile(r, f)
      close(f)

new(N) # init dummy node for splay algorithm

{.pop.}
