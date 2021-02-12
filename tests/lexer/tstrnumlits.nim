discard """
  output: "[[1]]neg[[1]][[1]][[12345.67890]][[12345.67890]][[1]]times[[1]][[1]]plusneg[[1]][[1]][[22.40]][[0x5a3a]]neg[[38383839292839283928392839283928392839283.928493849385935898243e-50000]]"
"""
# Test tkStrNumLit

type
  S = distinct string

proc wrap(number: string): S =
  result = ("[[" & number & "]]").S

template twrap(number: string): untyped =
  wrap(number)

proc extraContext(): S =
  22.40wrap

# if a user is writing a numberic library, they might write proc similar to:

proc `*`(left, right: S): S =
  result = (left.string & "times" & right.string).S

proc `+`(left, right: S): S =
  result = (left.string & "plus" & right.string).S

proc `-`(number: S): S =
  result = ("neg" & number.string).S

proc `$`(number: S): string =
  result = number.string

const
  likeInteger    = 1wrap
  negative       = -1wrap
  quoted         = 1wrap      # 1'wrap
  likeFloat      = 12345.67890wrap
  quotedFloat    = 12345.67890wrap # 12345.67890'wrap
  smushed        = 1wrap*1wrap
  borderCase     = 1wrap + -1wrap
  usingTemplate  = 1twrap
  inProc         = extraContext()
  hex            = 0x5a3awrap  # Note: starting a suffix with the letters `a` to `f` is NOT a good idea
  reallyBig      = -38383839292839283928392839283928392839283.928493849385935898243e-50000wrap

stdout.write(likeInteger.string)
stdout.write(negative.string)
stdout.write(quoted.string)
stdout.write(likeFloat.string)
stdout.write(quotedFloat.string)
stdout.write(smushed.string)
stdout.write(borderCase.string)
stdout.write(usingTemplate.string)
stdout.write(inProc.string)
stdout.write(hex.string)
stdout.writeLine(reallyBig.string)

assert $1234.56wrap == $("1234.56".wrap)

# verify that the i64, f32, etc in-built suffixes still parse correctly

const expectedF32: float32 = 123.125
var stillRealFloat = 123.125f32
assert stillRealFloat == expectedF32
stillRealFloat = 123.125'f32
assert stillRealFloat == expectedF32
stillRealFloat = 123.125e0'f32
assert stillRealFloat == expectedF32

# if not a built-in suffix, test that we can parse as a user supplied suffix

proc fa(number: string): S =   # proc starts with 'f' just like 'f32'
  result = wrap(number)

proc da(number: string): S =   # proc starts with 'd' just like the d suffix
  result = wrap(number)

proc ia(number: string): S =   # proc starts with 'i' just like 'i64'
  result = wrap(number)

proc ua(number: string): S =   # proc starts with 'u' just like 'u8'
  result = wrap(number)


assert $1234.56wrap == $1234.56fa  # using a suffix that starts with `a` to `f` is allowed but not wise.
assert $1234.56wrap == $1234.56'fa
assert $1234.56wrap == $1234.56da
assert $1234.56wrap == $1234.56'da
assert $1234.56wrap == $1234.56ia
assert $1234.56wrap == $1234.56'ia
assert $1234.56wrap == $1234.56ua
assert $1234.56wrap == $1234.56'ua
