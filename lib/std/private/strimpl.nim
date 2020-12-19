func toLowerAscii*(c: char): char {.inline.} =
  if c in {'A'..'Z'}:
    result = chr(ord(c) + (ord('a') - ord('A')))
  else:
    result = c

template cmpIgnoreStyleImpl*(a, b: typed, firstCharCaseSensitive: static bool = false) =
  # a, b are string or cstring
  let aLen = a.len
  let bLen = b.len
  when firstCharCaseSensitive:
    if a[0] != b[0]: return ord(a[0]) - ord(b[0])
  var i = 0
  var j = 0
  while true:
    while i < aLen and a[i] == '_': inc i
    while j < bLen and b[j] == '_': inc j
    let aa = if i < aLen: toLowerAscii(a[i]) else: '\0'
    let bb = if j < bLen: toLowerAscii(b[j]) else: '\0'
    result = ord(aa) - ord(bb)
    if result != 0: return result
    # the characters are identical:
    if i >= aLen:
      # both cursors at the end:
      if j >= bLen: return 0
      # not yet at the end of 'b':
      return -1
    elif j >= bLen:
      return 1
    inc i
    inc j

template cmpIgnoreCaseImpl*(a, b: typed, firstCharCaseSensitive: static bool = false) =
  # a, b are string or cstring
  let aLen = a.len
  let bLen = b.len
  when firstCharCaseSensitive:
    if a[0] != b[0]: return ord(a[0]) - ord(b[0])
  var i = 0
  var m = min(aLen, bLen)
  while i < m:
    result = ord(toLowerAscii(a[i])) - ord(toLowerAscii(b[i]))
    if result != 0: return
    inc(i)
  result = aLen - bLen
