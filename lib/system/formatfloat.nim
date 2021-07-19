#
#
#            Nim's Runtime Library
#        (c) Copyright 2019 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# when defined(nimFpRoundtrips) and not defined(nimscript) and
#     not defined(js) and defined(nimHasDragonBox):

# import system/memory
proc c_memcpy(a, b: pointer, size: csize_t): pointer {.importc: "memcpy", header: "<string.h>", discardable.}
proc addCstringN(result: var string, buf: cstring; buflen: int) =
  # no nimvm support needed, so it doesn't need to be fast here either
  let oldLen = result.len
  let newLen = oldLen + buflen
  result.setLen newLen
  # when defined(js):
  #   # debugEcho()
  #   # for i in oldLen..<newLen:
  #   for i in 0..<buflen:
  #     result[oldLen + i] = buf[i]
  # else:
  # copyMem(result[oldLen].addr, buf, buflen)
  c_memcpy(result[oldLen].addr, buf, buflen.csize_t)

import dragonbox

proc writeFloatToBufferRoundtrip*(buf: var array[65, char]; value: BiggestFloat): int =
  ## This is the implementation to format floats.
  ##
  ## returns the amount of bytes written to `buf` not counting the
  ## terminating '\0' character.
  result = toChars(buf, value, forceTrailingDotZero=true)
  buf[result] = '\0'

proc c_sprintf(buf, frmt: cstring): cint {.header: "<stdio.h>",
                                    importc: "sprintf", varargs, noSideEffect.}

proc writeToBuffer(buf: var array[65, char]; value: cstring) =
  var i = 0
  while value[i] != '\0':
    buf[i] = value[i]
    inc i

proc writeFloatToBufferSprintf*(buf: var array[65, char]; value: BiggestFloat): int =
  ## This is the implementation to format floats.
  ##
  ## returns the amount of bytes written to `buf` not counting the
  ## terminating '\0' character.
  var n: int = c_sprintf(addr buf, "%.16g", value)
  var hasDot = false
  for i in 0..n-1:
    if buf[i] == ',':
      buf[i] = '.'
      hasDot = true
    elif buf[i] in {'a'..'z', 'A'..'Z', '.'}:
      hasDot = true
  if not hasDot:
    buf[n] = '.'
    buf[n+1] = '0'
    buf[n+2] = '\0'
    result = n + 2
  else:
    result = n
  # On Windows nice numbers like '1.#INF', '-1.#INF' or '1.#NAN' or 'nan(ind)'
  # of '-1.#IND' are produced.
  # We want to get rid of these here:
  if buf[n-1] in {'n', 'N', 'D', 'd', ')'}:
    writeToBuffer(buf, "nan")
    result = 3
  elif buf[n-1] == 'F':
    if buf[0] == '-':
      writeToBuffer(buf, "-inf")
      result = 4
    else:
      writeToBuffer(buf, "inf")
      result = 3

# when defined(nimFpRoundtrips) and not defined(nimscript) and
#     not defined(js) and defined(nimHasDragonBox):
#   import dragonbox

proc writeFloatToBuffer*(buf: var array[65, char]; value: BiggestFloat): int {.inline.} =
  when defined(nimFpRoundtrips):
    writeFloatToBufferRoundtrip(buf, value)
  else:
    writeFloatToBufferSprintf(buf, value)

proc addFloatRoundtrip*(result: var string; x: float) =
  when nimvm:
    doAssert false
  else:
    var buffer {.noinit.}: array[65, char]
    let n = writeFloatToBufferRoundtrip(buffer, x)
    result.addCstringN(cstring(buffer[0].addr), n)

proc addFloatSprintf*(result: var string; x: float) =
  when nimvm:
    doAssert false
  else:
    var buffer {.noinit.}: array[65, char]
    let n = writeFloatToBufferSprintf(buffer, x)
    result.addCstringN(cstring(buffer[0].addr), n)

proc nimFloatToString(a: float): cstring =
  ## ensures the result doesn't print like an integer, i.e. return 2.0, not 2
  # print `-0.0` properly
  asm """
    function nimOnlyDigitsOrMinus(n) {
      return n.toString().match(/^-?\d+$/);
    }
    if (Number.isSafeInteger(`a`))
      `result` = `a` === 0 && 1 / `a` < 0 ? "-0.0" : `a`+".0"
    else {
      `result` = `a`+""
      if(nimOnlyDigitsOrMinus(`result`)){
        `result` = `a`+".0"
      }
    }
  """

proc addFloat*(result: var string; x: float) {.inline.} =
  ## Converts float to its string representation and appends it to `result`.
  ##
  ## .. code-block:: Nim
  ##   var
  ##     a = "123"
  ##     b = 45.67
  ##   a.addFloat(b) # a <- "12345.67"
  template impl =
    when defined(nimFpRoundtrips):
      addFloatRoundtrip(result, x)
    else:
      addFloatSprintf(result, x)
  when defined(js):
    when nimvm: impl()
    else:
      # result.add $nimFloatToString(x)
      # result.add cstrToNimstr(nimFloatToString(x))
      let tmp = nimFloatToString(x)
      for i in 0..<tmp.len:
        result.add tmp[i]
  else: impl()

proc nimFloatToStr(f: float): string {.compilerproc.} =
  result = newStringOfCap(8)
  result.addFloat f

when defined(nimFpRoundtrips) and not defined(nimscript) and
    not defined(js) and defined(nimHasDragonBox):
  import schubfach

proc nimFloat32ToStr(f: float32): string {.compilerproc.} =
  when declared(float32ToChars):
    result = newString(65)
    let L = float32ToChars(result, f, forceTrailingDotZero=true)
    setLen(result, L)
  else:
    result = newStringOfCap(8)
    result.addFloat f
