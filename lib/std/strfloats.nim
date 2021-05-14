#
#
#            Nim's Runtime Library
#        (c) Copyright 2019 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

#[
## TODO
* support more efficient dragonbox API for float32
* support more rounding modes and other options, see https://github.com/jk-jeon/dragonbox
]#


const useDragonbox = defined(nimHasDragonbox) and not defined(nimLegacyAddFloat) and not defined(nimscript)

const dragonboxBufLen = 64
  # see justification for 64 here: https://github.com/abolz/Drachennest/blob/master/src/dragonbox.h

const strFloatBufLen* = dragonboxBufLen

when not defined(nimscript): # eg for `tests/stdlib/tlwip.nim`
  from system/memory import nimCopyMem

proc addCharsN*(result: var string, buf: ptr char; n: int) = # PRTEMP MOVE
  let oldLen = result.len
  result.setLen oldLen + n
  when declared(nimCopyMem):
    nimCopyMem(result[oldLen].addr, buf, n)
  else:
    doAssert false

proc addCstring(result: var array[strFloatBufLen, char], buf: openArray[char]) {.inline.} =
  for i in 0..<buf.len:
    result[i] = buf[i]

proc toStringSprintf*(buf: var array[strFloatBufLen, char]; value: BiggestFloat): int =
  ## This is the old implementation to format floats in the Nim
  ## programming language.
  ##
  ## * `buf` - A buffer to write into. The buffer does not need to be initialized.
  proc c_sprintf(buf, frmt: cstring): cint {.header: "<stdio.h>", importc: "sprintf", varargs, noSideEffect.}
  let n: int = c_sprintf(addr buf, "%.16g", value)
  var hasDot = false
  for i in 0..<n:
    # compensate for some `LC_NUMERIC` values, refs https://linux.die.net/man/3/sprintf
    # xxx incorrect in this edge case: "1.234.567,89" in the da_DK locale.
    if buf[i] == ',':
      buf[i] = '.'
      hasDot = true
    elif buf[i] in {'a'..'z', 'A'..'Z', '.'}:
      hasDot = true
  if not hasDot: # 12 => 12.0
    buf[n] = '.'
    buf[n+1] = '0'
    result = n + 2
  else:
    result = n
  # On Windows nice numbers like '1.#INF', '-1.#INF' or '1.#NAN' or 'nan(ind)'
  # of '-1.#IND' are produced.
  # We want to get rid of these here:
  if buf[n-1] in {'n', 'N', 'D', 'd', ')'}:
    addCstring(buf, "nan")
    result = 3
  elif buf[n-1] == 'F':
    if buf[0] == '-':
      addCstring(buf, "-inf")
      result = 4
    else:
      addCstring(buf, "inf")
      result = 3

when useDragonbox:
  import private/dependency_utils
  addDependency("dragonbox")
  proc dragonboxToString(buf: ptr char, value: cdouble): ptr char {.importc: "nim_dragonbox_Dtoa".}

  proc toStringDragonbox*(buf: var array[strFloatBufLen, char]; value: BiggestFloat): int {.inline.} =
    let first = buf[0].addr
    let ret = dragonboxToString(first, value)
    result = cast[int](ret) - cast[int](first)
    if buf[result-1] in {'f', 'n'}: # inf, -inf, nan
      return result
    for i in 0..<result: # 12 => 12.0
      if buf[i] in {'.', 'e'}: # if needed, we could make 1e2 print as 1.0e2
        return result
    buf[result] = '.'
    buf[result+1] = '0'
    result += 2

  template toString*(buf: var array[strFloatBufLen, char]; value: BiggestFloat): int =
    toStringDragonbox(buf, value)
else:
  template toString*(buf: var array[strFloatBufLen, char]; value: BiggestFloat): int =
    toStringSprintf(buf, value)

proc addFloat*(result: var string; x: float) =
  ## Converts `x` to its string representation and appends it to `result`.
  ##
  ## The algorithm is implementation defined, but currently uses dragonbox algorithm,
  ## which ensures roundtrip guarantee, minimum length, and correct rounding.
  runnableExamples:
    var a = "prefix:"
    a.addFloat(0.1)
    assert a == "prefix:0.1"

    a.setLen 0
    var b = 0.1
    var c = b + 0.2
    a.addFloat(c)
    assert a == "0.30000000000000004"
    assert c != 0.3 # indeed, binary representation is not exact
  when nimvm: # also a vmops, after bootstrap
    result.add $x
  else:
    var buf {.noinit.}: array[strFloatBufLen, char]
    let n = toString(buf, x)
    result.addCharsN(buf[0].addr, n)
