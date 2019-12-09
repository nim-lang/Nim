#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Ropes for the C code generator
#
#  Ropes are a data structure that represents a very long string
#  efficiently; especially concatenation is done in O(1) instead of O(N).
#  Ropes make use a lazy evaluation: They are essentially concatenation
#  trees that are only flattened when converting to a native Nim
#  string or when written to disk. The empty string is represented by a
#  nil pointer.
#  A little picture makes everything clear:
#
#  "this string" & " is internally " & "represented as"
#
#             con  -- inner nodes do not contain raw data
#            /   \
#           /     \
#          /       \
#        con       "represented as"
#       /   \
#      /     \
#     /       \
#    /         \
#   /           \
#"this string"  " is internally "
#
#  Note that this is the same as:
#  "this string" & (" is internally " & "represented as")
#
#             con
#            /   \
#           /     \
#          /       \
# "this string"    con
#                 /   \
#                /     \
#               /       \
#              /         \
#             /           \
#" is internally "        "represented as"
#
#  The 'con' operator is associative! This does not matter however for
#  the algorithms we use for ropes.
#
#  Note that the left and right pointers are not needed for leaves.
#  Leaves have relatively high memory overhead (~30 bytes on a 32
#  bit machines) and we produce many of them. This is why we cache and
#  share leaves across different rope trees.
#  To cache them they are inserted in a `cache` array.

import
  hashes

from pathutils import AbsoluteFile

type
  FormatStr* = string  # later we may change it to CString for better
                       # performance of the code generator (assignments
                       # copy the format strings
                       # though it is not necessary)
  Rope* = ref RopeObj
  RopeObj*{.acyclic.} = object of RootObj # the empty rope is represented
                                          # by nil to safe space
    left, right: Rope
    L: int                    # <= 0 if a leaf
    data*: string

proc len*(a: Rope): int =
  ## the rope's length
  if a == nil: result = 0
  else: result = abs a.L

proc newRope(data: string = ""): Rope =
  new(result)
  result.L = -data.len
  result.data = data

when not compileOption("threads"):
  var
    cache: array[0..2048*2 - 1, Rope]

  proc resetRopeCache* =
    for i in low(cache)..high(cache):
      cache[i] = nil

proc ropeInvariant(r: Rope): bool =
  if r == nil:
    result = true
  else:
    result = true #
                  #    if r.data <> snil then
                  #      result := true
                  #    else begin
                  #      result := (r.left <> nil) and (r.right <> nil);
                  #      if result then result := ropeInvariant(r.left);
                  #      if result then result := ropeInvariant(r.right);
                  #    end

var gCacheTries* = 0
var gCacheMisses* = 0
var gCacheIntTries* = 0

proc insertInCache(s: string): Rope =
  when declared(cache):
    inc gCacheTries
    var h = hash(s) and high(cache)
    result = cache[h]
    if isNil(result) or result.data != s:
      inc gCacheMisses
      result = newRope(s)
      cache[h] = result
  else:
    result = newRope(s)

proc rope*(s: string): Rope =
  ## Converts a string to a rope.
  if s.len == 0:
    result = nil
  else:
    result = insertInCache(s)
  assert(ropeInvariant(result))

proc rope*(i: BiggestInt): Rope =
  ## Converts an int to a rope.
  inc gCacheIntTries
  result = rope($i)

proc rope*(f: BiggestFloat): Rope =
  ## Converts a float to a rope.
  result = rope($f)

proc `&`*(a, b: Rope): Rope =
  if a == nil:
    result = b
  elif b == nil:
    result = a
  else:
    result = newRope()
    result.L = abs(a.L) + abs(b.L)
    result.left = a
    result.right = b

proc `&`*(a: Rope, b: string): Rope =
  ## the concatenation operator for ropes.
  result = a & rope(b)

proc `&`*(a: string, b: Rope): Rope =
  ## the concatenation operator for ropes.
  result = rope(a) & b

proc `&`*(a: openArray[Rope]): Rope =
  ## the concatenation operator for an openarray of ropes.
  for i in 0..high(a): result = result & a[i]

proc add*(a: var Rope, b: Rope) =
  ## adds `b` to the rope `a`.
  a = a & b

proc add*(a: var Rope, b: string) =
  ## adds `b` to the rope `a`.
  a = a & b

iterator leaves*(r: Rope): string =
  ## iterates over any leaf string in the rope `r`.
  if r != nil:
    var stack = @[r]
    while stack.len > 0:
      var it = stack.pop
      while it.left != nil:
        assert it.right != nil
        stack.add(it.right)
        it = it.left
        assert(it != nil)
      yield it.data

iterator items*(r: Rope): char =
  ## iterates over any character in the rope `r`.
  for s in leaves(r):
    for c in items(s): yield c

proc writeRope*(f: File, r: Rope) =
  ## writes a rope to a file.
  for s in leaves(r): write(f, s)

proc writeRope*(head: Rope, filename: AbsoluteFile): bool =
  var f: File
  if open(f, filename.string, fmWrite):
    if head != nil: writeRope(f, head)
    close(f)
    result = true
  else:
    result = false

proc `$`*(r: Rope): string =
  ## converts a rope back to a string.
  result = newString(r.len)
  setLen(result, 0)
  for s in leaves(r): result.add(s)

proc ropeConcat*(a: varargs[Rope]): Rope =
  # not overloaded version of concat to speed-up `rfmt` a little bit
  for i in 0..high(a): result = result & a[i]

proc prepend*(a: var Rope, b: Rope) = a = b & a
proc prepend*(a: var Rope, b: string) = a = b & a

proc runtimeFormat*(frmt: FormatStr, args: openArray[Rope]): Rope =
  var i = 0
  result = nil
  var num = 0
  while i < frmt.len:
    if frmt[i] == '$':
      inc(i)                  # skip '$'
      case frmt[i]
      of '$':
        result.add("$")
        inc(i)
      of '#':
        inc(i)
        result.add(args[num])
        inc(num)
      of '0'..'9':
        var j = 0
        while true:
          j = j * 10 + ord(frmt[i]) - ord('0')
          inc(i)
          if i >= frmt.len or frmt[i] notin {'0'..'9'}: break
        num = j
        if j > high(args) + 1:
          doAssert false, "invalid format string: " & frmt
        else:
          result.add(args[j-1])
      of '{':
        inc(i)
        var j = 0
        while frmt[i] in {'0'..'9'}:
          j = j * 10 + ord(frmt[i]) - ord('0')
          inc(i)
        num = j
        if frmt[i] == '}': inc(i)
        else:
          doAssert false, "invalid format string: " & frmt

        if j > high(args) + 1:
          doAssert false, "invalid format string: " & frmt
        else:
          result.add(args[j-1])
      of 'n':
        result.add("\n")
        inc(i)
      of 'N':
        result.add("\n")
        inc(i)
      else:
        doAssert false, "invalid format string: " & frmt
    var start = i
    while i < frmt.len:
      if frmt[i] != '$': inc(i)
      else: break
    if i - 1 >= start:
      result.add(substr(frmt, start, i - 1))
  assert(ropeInvariant(result))

proc `%`*(frmt: static[FormatStr], args: openArray[Rope]): Rope =
  runtimeFormat(frmt, args)

template addf*(c: var Rope, frmt: FormatStr, args: openArray[Rope]) =
  ## shortcut for ``add(c, frmt % args)``.
  c.add(frmt % args)

when true:
  template `~`*(r: string): Rope = r % []
else:
  {.push stack_trace: off, line_trace: off.}
  proc `~`*(r: static[string]): Rope =
    # this is the new optimized "to rope" operator
    # the mnemonic is that `~` looks a bit like a rope :)
    var r {.global.} = r % []
    return r
  {.pop.}

const
  bufSize = 1024              # 1 KB is reasonable

proc equalsFile*(r: Rope, f: File): bool =
  ## returns true if the contents of the file `f` equal `r`.
  var
    buf: array[bufSize, char]
    bpos = buf.len
    blen = buf.len
    btotal = 0
    rtotal = 0

  for s in leaves(r):
    var spos = 0
    rtotal += s.len
    while spos < s.len:
      if bpos == blen:
        # Read more data
        bpos = 0
        blen = readBuffer(f, addr(buf[0]), buf.len)
        btotal += blen
        if blen == 0:  # no more data in file
          result = false
          return
      let n = min(blen - bpos, s.len - spos)
      # TODO There's gotta be a better way of comparing here...
      if not equalMem(addr(buf[bpos]), cast[pointer](cast[int](cstring(s))+spos), n):
        result = false
        return
      spos += n
      bpos += n

  result = readBuffer(f, addr(buf[0]), 1) == 0 and
      btotal == rtotal # check that we've read all

proc equalsFile*(r: Rope, filename: AbsoluteFile): bool =
  ## returns true if the contents of the file `f` equal `r`. If `f` does not
  ## exist, false is returned.
  var f: File
  result = open(f, filename.string)
  if result:
    result = equalsFile(r, f)
    close(f)

proc writeRopeIfNotEqual*(r: Rope, filename: AbsoluteFile): bool =
  # returns true if overwritten
  if not equalsFile(r, filename):
    result = writeRope(r, filename)
  else:
    result = false
