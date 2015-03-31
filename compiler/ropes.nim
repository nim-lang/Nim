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
  platform, hashes

type
  FormatStr* = string  # later we may change it to CString for better
                       # performance of the code generator (assignments
                       # copy the format strings
                       # though it is not necessary)
  Rope* = ref RopeObj
  RopeObj*{.acyclic.} = object of RootObj # the empty rope is represented
                                          # by nil to safe space
    left*, right*: Rope
    length*: int
    data*: string             # != nil if a leaf

  RopeSeq* = seq[Rope]

  RopesError* = enum
    rCannotOpenFile
    rInvalidFormatStr

{.deprecated: [TFormatStr: FormatStr].}
{.deprecated: [PRope: Rope].}
{.deprecated: [TRopeSeq: RopeSeq].}
{.deprecated: [TRopesError: RopesError].}

# implementation

var errorHandler*: proc(err: RopesError, msg: string, useWarning = false)
  # avoid dependency on msgs.nim

proc len*(a: Rope): int =
  if a == nil: result = 0
  else: result = a.length

proc newRope(data: string = nil): Rope =
  new(result)
  if data != nil:
    result.length = len(data)
    result.data = data

proc newMutableRope*(capacity = 30): Rope =
  ## creates a new rope that supports direct modifications of the rope's
  ## 'data' and 'length' fields.
  new(result)
  result.data = newStringOfCap(capacity)

proc freezeMutableRope*(r: Rope) {.inline.} =
  r.length = r.data.len

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
  inc gCacheTries
  var h = hash(s) and high(cache)
  result = cache[h]
  if isNil(result) or result.data != s:
    inc gCacheMisses
    result = newRope(s)
    cache[h] = result

proc rope*(s: string): Rope =
  if s.len == 0:
    result = nil
  else:
    result = insertInCache(s)
  assert(ropeInvariant(result))

proc rope*(i: BiggestInt): Rope =
  inc gCacheIntTries
  result = rope($i)

proc rope*(f: BiggestFloat): Rope =
  result = rope($f)

# TODO Old names - change invokations to rope
proc toRope*(s: string): Rope {.deprecated.} =
  result = rope(s)
proc toRope*(i: BiggestInt): Rope {.deprecated.}  =
  result = rope(i)

proc ropeSeqInsert(rs: var RopeSeq, r: Rope, at: Natural) =
  var length = len(rs)
  if at > length:
    setLen(rs, at + 1)
  else:
    setLen(rs, length + 1)    # move old rope elements:
  for i in countdown(length, at + 1):
    rs[i] = rs[i - 1] # this is correct, I used pen and paper to validate it
  rs[at] = r

proc newRecRopeToStr(result: var string, resultLen: var int, r: Rope) =
  var stack = @[r]
  while len(stack) > 0:
    var it = pop(stack)
    while it.data == nil:
      add(stack, it.right)
      it = it.left
    assert(it.data != nil)
    copyMem(addr(result[resultLen]), addr(it.data[0]), it.length)
    inc(resultLen, it.length)
    assert(resultLen <= len(result))

proc `&`*(a, b: Rope): Rope =
  if a == nil:
    result = b
  elif b == nil:
    result = a
  else:
    result = newRope()
    result.length = a.length + b.length
    result.left = a
    result.right = b

proc `&`*(a: Rope, b: string): Rope =
  result = a & rope(b)

proc `&`*(a: string, b: Rope): Rope =
  result = rope(a) & b

proc `&`*(a: openArray[Rope]): Rope =
  for i in countup(0, high(a)): result = result & a[i]

proc add*(a: var Rope, b: Rope) =
  a = a & b

proc add*(a: var Rope, b: string) =
  a = a & b

proc `$`*(p: Rope): string =
  if p == nil:
    result = ""
  else:
    result = newString(p.length)
    var resultLen = 0
    newRecRopeToStr(result, resultLen, p)

# TODO Old names - change invokations to `&`
proc con*(a, b: Rope): Rope {.deprecated.} = a & b
proc con*(a: Rope, b: string): Rope {.deprecated.} = a & b
proc con*(a: string, b: Rope): Rope {.deprecated.} = a & b
proc con*(a: varargs[Rope]): Rope {.deprecated.} = `&`(a)

proc ropeConcat*(a: varargs[Rope]): Rope =
  # not overloaded version of concat to speed-up `rfmt` a little bit
  for i in countup(0, high(a)): result = con(result, a[i])

# TODO Old names - change invokations to add
proc app*(a: var Rope, b: Rope) {.deprecated.} = add(a, b)
proc app*(a: var Rope, b: string) {.deprecated.} = add(a, b)

proc prepend*(a: var Rope, b: Rope) = a = b & a
proc prepend*(a: var Rope, b: string) = a = b & a

proc writeRope*(f: File, c: Rope) =
  var stack = @[c]
  while len(stack) > 0:
    var it = pop(stack)
    while it.data == nil:
      add(stack, it.right)
      it = it.left
      assert(it != nil)
    assert(it.data != nil)
    write(f, it.data)

proc writeRope*(head: Rope, filename: string, useWarning = false) =
  var f: File
  if open(f, filename, fmWrite):
    if head != nil: writeRope(f, head)
    close(f)
  else:
    errorHandler(rCannotOpenFile, filename, useWarning)

var
  rnl* = tnl.newRope
  softRnl* = tnl.newRope

proc `%`*(frmt: TFormatStr, args: openArray[Rope]): Rope =
  var i = 0
  var length = len(frmt)
  result = nil
  var num = 0
  while i < length:
    if frmt[i] == '$':
      inc(i)                  # skip '$'
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
          if (i >= length) or frmt[i] notin {'0'..'9'}: break
        num = j
        if j > high(args) + 1:
          errorHandler(rInvalidFormatStr, $(j))
        else:
          add(result, args[j-1])
      of '{':
        inc(i)
        var j = 0
        while i < length and frmt[i] in {'0'..'9'}:
          j = j * 10 + ord(frmt[i]) - ord('0')
          inc(i)
        num = j
        if i < length and frmt[i] == '}': inc(i)
        else: errorHandler(rInvalidFormatStr, $(frmt[i]))

        if j > high(args) + 1:
          errorHandler(rInvalidFormatStr, $(j))
        else:
          add(result, args[j-1])
      of 'n':
        add(result, softRnl)
        inc(i)
      of 'N':
        add(result, rnl)
        inc(i)
      else:
        errorHandler(rInvalidFormatStr, $(frmt[i]))
    var start = i
    while i < length:
      if frmt[i] != '$': inc(i)
      else: break
    if i - 1 >= start:
      add(result, substr(frmt, start, i - 1))
  assert(ropeInvariant(result))

proc addf*(c: var Rope, frmt: TFormatStr, args: openArray[Rope]) =
  add(c, frmt % args)

# TODO Compatibility names
proc ropef*(frmt: TFormatStr, args: varargs[Rope]): Rope {.deprecated.} =
  result = frmt % args
proc appf*(c: var Rope, frmt: TFormatStr, args: varargs[Rope]) {.deprecated.} =
  addf(c, frmt, args)

when true:
  template `~`*(r: string): Rope = r.ropef
else:
  {.push stack_trace: off, line_trace: off.}
  proc `~`*(r: static[string]): Rope =
    # this is the new optimized "to rope" operator
    # the mnemonic is that `~` looks a bit like a rope :)
    var r {.global.} = r.ropef
    return r
  {.pop.}

const
  bufSize = 1024              # 1 KB is reasonable

proc auxEqualsFile(r: Rope, f: File, buf: var array[bufSize, char],
                   bpos, blen: var int): bool =
  if r.data != nil:
    var dpos = 0
    let dlen = r.data.len
    while dpos < dlen:
      if bpos == blen:
        # Read more data
        bpos = 0
        blen = readBuffer(f, addr(buf[0]), buf.len)
        if blen == 0:  # no more data in file
          result = false
          return
      let n = min(blen - bpos, dlen - dpos)
      if not equalMem(addr(buf[bpos]), addr(r.data[dpos]), n):
        result = false
        return
      dpos += n
      bpos += n
    result = true
  else:
    result = auxEqualsFile(r.left, f, buf, bpos, blen) and
             auxEqualsFile(r.right, f, buf, bpos, blen)

proc equalsFile*(r: Rope, f: File): bool =
  var
    buf: array[bufSize, char]
    bpos = bufSize
    blen = bufSize
  result = auxEqualsFile(r, f, buf, bpos, blen) and
           readBuffer(f, addr(buf[0]), 1) == 0  # check that we've read all

proc equalsFile*(r: Rope, filename: string): bool =
  var f: File
  result = open(f, filename)
  if result:
    result = equalsFile(r, f)
    close(f)

proc writeRopeIfNotEqual*(r: Rope, filename: string): bool =
  # returns true if overwritten
  if not equalsFile(r, filename):
    writeRope(r, filename)
    result = true
  else:
    result = false
