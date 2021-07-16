#
#
#            Nim's Runtime Library
#        (c) Copyright 2019 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

when defined(nimFpRoundtrips) and not defined(nimscript) and
    not defined(js) and defined(nimHasDragonBox):
  import dragonbox

  proc writeFloatToBuffer*(buf: var array[65, char]; value: BiggestFloat): int =
    ## This is the implementation to format floats.
    ##
    ## returns the amount of bytes written to `buf` not counting the
    ## terminating '\0' character.
    result = toChars(buf, value, forceTrailingDotZero=true)
    buf[result] = '\0'

else:
  proc c_sprintf(buf, frmt: cstring): cint {.header: "<stdio.h>",
                                      importc: "sprintf", varargs, noSideEffect.}

  proc writeToBuffer(buf: var array[65, char]; value: cstring) =
    var i = 0
    while value[i] != '\0':
      buf[i] = value[i]
      inc i

  proc writeFloatToBuffer*(buf: var array[65, char]; value: BiggestFloat): int =
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
