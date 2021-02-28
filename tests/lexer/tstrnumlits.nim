# Test tkStrNumLit

type
  S = distinct string

proc `'wrap`(number: string): S =
  result = ("[[" & number & "]]").S

template `'twrap`(number: string): untyped =
  number.`'wrap`

proc extraContext(): S =
  22.40'wrap

# if a user is writing a numeric library, they might write op procs similar to:

proc `*`(left, right: S): S =
  result = (left.string & "times" & right.string).S

proc `+`(left, right: S): S =
  result = (left.string & "plus" & right.string).S

proc `$`(number: S): string =
  result = number.string

doAssert string(1'wrap) == "[[1]]":
  "unable to resolve an integer-suffix pattern"

doAssert string(-1'wrap) == "[[-1]]":
  "unable to resolve a negative integer-suffix pattern"

doAssert string(12345.67890'wrap) == "[[12345.67890]]":
  "unable to resolve a float-suffix pattern"

doAssert string(1'wrap*1'wrap) == "[[1]]times[[1]]":
  "unable to resolve an operator between two suffixed numeric literals"

doAssert string(1'wrap+ -1'wrap) == "[[1]]plus[[-1]]":
  "unable to resolve a negative suffixed numeric literal following an operator"

doAssert string(1'twrap) == "[[1]]":
  "unable to resolve a template using a suffixed numeric literal"

doAssert string(extraContext()) == "[[22.40]]":
  "unable to return a suffixed numeric literal by an implicit return"

doAssert string(0x5a3a'wrap) == "[[0x5a3a]]":
  "unable to handle a suffixed numeric hex literal"

doAssert string(0o5732'wrap) == "[[0o5732]]":
  "unable to handle a suffixed numeric octal literal"

doAssert string(0b0101111010101'wrap) == "[[0b0101111010101]]":
  "unable to handle a suffixed numeric binary literal"

doAssert string(-38383839292839283928392839283928392839283.928493849385935898243e-50000'wrap) == "[[-38383839292839283928392839283928392839283.928493849385935898243e-50000]]":
  "unable to handle a very long numeric literal with a user-supplied suffix"

doAssert $1234.56'wrap == "[[1234.56]]":
  "unable to properly account for context with suffixed numeric literals"

# verify that the i64, f32, etc in-built suffixes still parse correctly

const expectedF32: float32 = 123.125

doAssert 123.125f32 == expectedF32:
  "Failing to support non-quoted legacy f32 floating point suffix"

doAssert 123.125'f32 == expectedF32

doAssert 123.125e0'f32 == expectedF32

# if not a built-in suffix, test that we can parse as a user supplied suffix

proc `'f9`(number: string): S =   # proc starts with 'f' just like 'f32'
  result = ("[[" & number & "]]").S

proc `'d9`(number: string): S =   # proc starts with 'd' just like the d suffix
  result = ("[[" & number & "]]").S

proc `'i9`(number: string): S =   # proc starts with 'i' just like 'i64'
  result = ("[[" & number & "]]").S

proc `'u9`(number: string): S =   # proc starts with 'u' just like 'u8'
  result = ("[[" & number & "]]").S

doAssert $1234.56'wrap == $1234.56'f9
doAssert $1234.56'wrap == $1234.56'd9
doAssert $1234.56'wrap == $1234.56'i9
doAssert $1234.56'wrap == $1234.56'u9
