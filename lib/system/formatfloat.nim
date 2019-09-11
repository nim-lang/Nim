
when not defined(js):
  proc c_sprintf(buf, frmt: cstring): cint {.header: "<stdio.h>",
                                     importc: "sprintf", varargs, noSideEffect.}

proc writeFloatToBuffer*(buf: var array[64, char]; value: BiggestFloat): int =
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

  # the output is some representation of "nan". Make it uniform on
  # all system and override the it with "nan"

  # On Windows nice numbers like '1.#INF', '-1.#INF' or '1.#NAN' of
  # '-1.#IND' are produced. We want to get rid of these here and
  # provide a uniform representation.
  if value != value: #is nan
    return c_sprintf(buf[0].addr, "nan")
  if value == Inf:
    return c_sprintf(buf[0].addr, "inf")
  if value == NegInf:
    return c_sprintf(buf[0].addr, "-inf")

  var n: int = c_sprintf(buf[0].addr, "%.16g", value)
  var hasDot = false
  for i in 0..n-1:
    # `sprintf` looks up the environment variable "LC_NUMERIC" for the
    # decimal separator and on some systems it will use a comma as a
    # decimal separator. We don't want to have such a behavior in the
    # Nim programming language.
    if buf[i] == ',':
      buf[i] = '.'
      hasDot = true
    elif buf[i] in {'a'..'z', 'A'..'Z', '.'}:
      # When the output is for example "1e10", we also don't want to append a ".0" postfix.
      hasDot = true
