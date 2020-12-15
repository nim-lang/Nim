proc handleHexChar*(c: char, x: var int): bool {.inline.} =
  ## Converts `%xx` hexadecimal to the ordinal number and adds the result to `x`.
  ## Returns `true` if `c` is not hexadecimal.
  ##
  ## When `c` is hexadecimal, the proc is equal to `x = x shl 4 + hex2Int(c)`.
  runnableExamples:
    var x: int = 0
    assert not handleHexChar('a', x)
    assert x == 10

    assert not handleHexChar('B', x)
    assert x == 171 # 10 << 4 + 11

    # failed
    assert handleHexChar('?', x)
  case c
  of '0'..'9': x = (x shl 4) or (ord(c) - ord('0'))
  of 'a'..'f': x = (x shl 4) or (ord(c) - ord('a') + 10)
  of 'A'..'F': x = (x shl 4) or (ord(c) - ord('A') + 10)
  else:
    result = true

proc decodePercent*(s: openArray[char], i: var int): char =
  ## Converts `%xx` hexadecimal to the character with ordinal number `xx`.
  ##
  ## If `xx` is not a valid hexadecimal value, it is left intact: only the
  ## leading `%` is returned as-is, and `xx` characters will be processed in the
  ## next step (e.g. in `uri.decodeUrl`) as regular characters.
  result = '%'
  if i+2 < s.len:
    var x = 0
    var failed = false
    failed = handleHexChar(s[i+1], x)
    failed = handleHexChar(s[i+2], x)
    if not failed:
      result = chr(x)
      inc(i, 2)
