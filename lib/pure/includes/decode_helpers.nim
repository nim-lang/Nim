# Include file that implements 'decodePercent' and friends. Do not import it!

proc handleHexChar(c: char, x: var int, f: var bool) {.inline.} =
  case c
  of '0'..'9': x = (x shl 4) or (ord(c) - ord('0'))
  of 'a'..'f': x = (x shl 4) or (ord(c) - ord('a') + 10)
  of 'A'..'F': x = (x shl 4) or (ord(c) - ord('A') + 10)
  else: f = true

proc decodePercent(s: string, i: var int): char =
  ## Converts `%xx` hexadecimal to the charracter with ordinal number `xx`.
  ##
  ## If `xx` is not a valid hexadecimal value, it is left intact: only the
  ## leading `%` is returned as-is, and `xx` characters will be processed in the
  ## next step (e.g. in `uri.decodeUrl`) as regular characters.
  result = '%'
  if i+2 < s.len:
    var x = 0
    var failed = false
    handleHexChar(s[i+1], x, failed)
    handleHexChar(s[i+2], x, failed)
    if not failed:
      result = chr(x)
      inc(i, 2)
