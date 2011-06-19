discard """
  output: "an identifier"
"""

const
  SymChars: set[char] = {'a'..'z', 'A'..'Z', '\x80'..'\xFF'}

proc classify(s: string) =
  case s[0]
  of SymChars, '_': echo "an identifier"
  of {'0'..'9'}: echo "a number"
  else: echo "other"

classify("Hurra")

