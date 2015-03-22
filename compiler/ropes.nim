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
  strutils, platform, hashes, crc, options

type
  TFormatStr* = string # later we may change it to CString for better
                       # performance of the code generator (assignments
                       # copy the format strings
                       # though it is not necessary)
  PRope* = ref TRope
  TRope*{.acyclic.} = object of RootObj # the empty rope is represented
                                        # by nil to safe space
    left*, right*: PRope
    length*: int
    data*: string             # != nil if a leaf

  TRopeSeq* = seq[PRope]

  TRopesError* = enum
    rCannotOpenFile
    rInvalidFormatStr
    rTokenTooLong

proc con*(a, b: PRope): PRope
proc con*(a: PRope, b: string): PRope
proc con*(a: string, b: PRope): PRope
proc con*(a: varargs[PRope]): PRope
proc app*(a: var PRope, b: PRope)
proc app*(a: var PRope, b: string)
proc prepend*(a: var PRope, b: PRope)
proc toRope*(s: string): PRope
proc toRope*(i: BiggestInt): PRope
proc ropeLen*(a: PRope): int
proc writeRopeIfNotEqual*(r: PRope, filename: string): bool
proc ropeToStr*(p: PRope): string
proc ropef*(frmt: TFormatStr, args: varargs[PRope]): PRope
proc appf*(c: var PRope, frmt: TFormatStr, args: varargs[PRope])
proc ropeEqualsFile*(r: PRope, f: string): bool
  # returns true if the rope r is the same as the contents of file f
proc ropeInvariant*(r: PRope): bool
  # exported for debugging
# implementation

var errorHandler*: proc(err: TRopesError, msg: string, useWarning = false)
  # avoid dependency on msgs.nim

proc ropeLen(a: PRope): int =
  if a == nil: result = 0
  else: result = a.length

proc newRope*(data: string = nil): PRope =
  new(result)
  if data != nil:
    result.length = len(data)
    result.data = data

proc newMutableRope*(capacity = 30): PRope =
  ## creates a new rope that supports direct modifications of the rope's
  ## 'data' and 'length' fields.
  new(result)
  result.data = newStringOfCap(capacity)

proc freezeMutableRope*(r: PRope) {.inline.} =
  r.length = r.data.len

var
  cache: array[0..2048*2 - 1, PRope]

proc resetRopeCache* =
  for i in low(cache)..high(cache):
    cache[i] = nil

proc ropeInvariant(r: PRope): bool =
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

proc insertInCache(s: string): PRope =
  inc gCacheTries
  var h = hash(s) and high(cache)
  result = cache[h]
  if isNil(result) or result.data != s:
    inc gCacheMisses
    result = newRope(s)
    cache[h] = result

proc toRope(s: string): PRope =
  if s.len == 0:
    result = nil
  else:
    result = insertInCache(s)
  assert(ropeInvariant(result))

proc ropeSeqInsert(rs: var TRopeSeq, r: PRope, at: Natural) =
  var length = len(rs)
  if at > length:
    setLen(rs, at + 1)
  else:
    setLen(rs, length + 1)    # move old rope elements:
  for i in countdown(length, at + 1):
    rs[i] = rs[i - 1] # this is correct, I used pen and paper to validate it
  rs[at] = r

proc newRecRopeToStr(result: var string, resultLen: var int, r: PRope) =
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

proc ropeToStr(p: PRope): string =
  if p == nil:
    result = ""
  else:
    result = newString(p.length)
    var resultLen = 0
    newRecRopeToStr(result, resultLen, p)

proc con(a, b: PRope): PRope =
  if a == nil: result = b
  elif b == nil: result = a
  else:
    result = newRope()
    result.length = a.length + b.length
    result.left = a
    result.right = b

proc con(a: PRope, b: string): PRope = result = con(a, toRope(b))
proc con(a: string, b: PRope): PRope = result = con(toRope(a), b)

proc con(a: varargs[PRope]): PRope =
  for i in countup(0, high(a)): result = con(result, a[i])

proc ropeConcat*(a: varargs[PRope]): PRope =
  # not overloaded version of concat to speed-up `rfmt` a little bit
  for i in countup(0, high(a)): result = con(result, a[i])

proc toRope(i: BiggestInt): PRope =
  inc gCacheIntTries
  result = toRope($i)

proc app(a: var PRope, b: PRope) = a = con(a, b)
proc app(a: var PRope, b: string) = a = con(a, b)
proc prepend(a: var PRope, b: PRope) = a = con(b, a)

proc writeRope*(f: File, c: PRope) =
  var stack = @[c]
  while len(stack) > 0:
    var it = pop(stack)
    while it.data == nil:
      add(stack, it.right)
      it = it.left
      assert(it != nil)
    assert(it.data != nil)
    write(f, it.data)

proc writeRope*(head: PRope, filename: string, useWarning = false) =
  var f: File
  if open(f, filename, fmWrite):
    if head != nil: writeRope(f, head)
    close(f)
  else:
    errorHandler(rCannotOpenFile, filename, useWarning)

var
  rnl* = tnl.newRope
  softRnl* = tnl.newRope

proc ropef(frmt: TFormatStr, args: varargs[PRope]): PRope =
  var i = 0
  var length = len(frmt)
  result = nil
  var num = 0
  while i <= length - 1:
    if frmt[i] == '$':
      inc(i)                  # skip '$'
      case frmt[i]
      of '$':
        app(result, "$")
        inc(i)
      of '#':
        inc(i)
        app(result, args[num])
        inc(num)
      of '0'..'9':
        var j = 0
        while true:
          j = (j * 10) + ord(frmt[i]) - ord('0')
          inc(i)
          if (i > length + 0 - 1) or not (frmt[i] in {'0'..'9'}): break
        num = j
        if j > high(args) + 1:
          errorHandler(rInvalidFormatStr, $(j))
        else:
          app(result, args[j - 1])
      of 'n':
        app(result, softRnl)
        inc i
      of 'N':
        app(result, rnl)
        inc(i)
      else:
        errorHandler(rInvalidFormatStr, $(frmt[i]))
    var start = i
    while i < length:
      if frmt[i] != '$': inc(i)
      else: break
    if i - 1 >= start:
      app(result, substr(frmt, start, i - 1))
  assert(ropeInvariant(result))

when true:
  template `~`*(r: string): PRope = r.ropef
else:
  {.push stack_trace: off, line_trace: off.}
  proc `~`*(r: static[string]): PRope =
    # this is the new optimized "to rope" operator
    # the mnemonic is that `~` looks a bit like a rope :)
    var r {.global.} = r.ropef
    return r
  {.pop.}

proc appf(c: var PRope, frmt: TFormatStr, args: varargs[PRope]) =
  app(c, ropef(frmt, args))

const
  bufSize = 1024              # 1 KB is reasonable

proc auxRopeEqualsFile(r: PRope, bin: var File, buf: pointer): bool =
  if r.data != nil:
    if r.length > bufSize:
      errorHandler(rTokenTooLong, r.data)
      return
    var readBytes = readBuffer(bin, buf, r.length)
    result = readBytes == r.length and
        equalMem(buf, addr(r.data[0]), r.length) # BUGFIX
  else:
    result = auxRopeEqualsFile(r.left, bin, buf)
    if result: result = auxRopeEqualsFile(r.right, bin, buf)

proc ropeEqualsFile(r: PRope, f: string): bool =
  var bin: File
  result = open(bin, f)
  if not result:
    return                    # not equal if file does not exist
  var buf = alloc(bufSize)
  result = auxRopeEqualsFile(r, bin, buf)
  if result:
    result = readBuffer(bin, buf, bufSize) == 0 # really at the end of file?
  dealloc(buf)
  close(bin)

proc crcFromRopeAux(r: PRope, startVal: TCrc32): TCrc32 =
  if r.data != nil:
    result = startVal
    for i in countup(0, len(r.data) - 1):
      result = updateCrc32(r.data[i], result)
  else:
    result = crcFromRopeAux(r.left, startVal)
    result = crcFromRopeAux(r.right, result)

proc newCrcFromRopeAux(r: PRope, startVal: TCrc32): TCrc32 =
  # XXX profiling shows this is actually expensive
  var stack: TRopeSeq = @[r]
  result = startVal
  while len(stack) > 0:
    var it = pop(stack)
    while it.data == nil:
      add(stack, it.right)
      it = it.left
    assert(it.data != nil)
    var i = 0
    var L = len(it.data)
    while i < L:
      result = updateCrc32(it.data[i], result)
      inc(i)

proc crcFromRope(r: PRope): TCrc32 =
  result = newCrcFromRopeAux(r, InitCrc32)

proc writeRopeIfNotEqual(r: PRope, filename: string): bool =
  # returns true if overwritten
  var c: TCrc32
  c = crcFromFile(filename)
  if c != crcFromRope(r):
    writeRope(r, filename)
    result = true
  else:
    result = false
