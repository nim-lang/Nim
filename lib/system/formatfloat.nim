#
#
#            Nim's Runtime Library
#        (c) Copyright 2019 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

proc c_sprintf(buf, frmt: cstring): cint {.header: "<stdio.h>",
                                    importc: "sprintf", varargs, noSideEffect.}

proc writeToBuffer(buf: var array[65, char]; value: cstring) =
  var i = 0
  while value[i] != '\0':
    buf[i] = value[i]
    inc i

proc writeFloatToBuffer*(buf: var array[65, char]; value: BiggestFloat, precision = -1): int =
  ## This is the implementation to format floats in the Nim
  ## programming language. The specific format for floating point
  ## numbers is not specified in the Nim programming language and
  ## might change slightly in the future, but at least wherever you
  ## format a float, it should be consistent.
  ##
  ## returns the amount of bytes written to `buf` not counting the
  ## terminating '\0' character.
  ##
  ## * `buf` - A buffer to write into. The buffer does not need to be
  ##           initialized and it will be overridden.
  ##
  let precision2 = if precision == -1: 16 else: precision

  var buf2 {.noinit.}: array[6, char] # 6 is just enough to hold `%.16g`
  var n2: int = c_sprintf(addr buf2,  "%%.%dg", precision2.cint)
  # if n2 <= 0: quit(1) # if want to be exact

  # this would fail for `tests/manyloc/standalone/barebone.nim`
  # var format = "%."
  # format.addInt(precision2)
  # format.add 'g'

  var n: int = c_sprintf(addr buf, addr buf2, value)
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
