func toLowerAscii*(c: char): char {.inline.} =
  if c in {'A'..'Z'}:
    result = chr(ord(c) + (ord('a') - ord('A')))
  else:
    result = c

template cmpIgnoreStyleImpl*(caseSensitive: static bool = false) =
  # a, b are string or cstring
  var i = 0
  var j = 0
  while true:
    while i < a.len and a[i] == '_': inc i
    while j < b.len and b[j] == '_': inc j
    let aa = if i < a.len: toLowerAscii(a[i]) else: '\0'
    let bb = if j < b.len: toLowerAscii(b[j]) else: '\0'
    result = ord(aa) - ord(bb)
    if result != 0: return result
    # the characters are identical:
    if i >= a.len:
      # both cursors at the end:
      if j >= b.len: return 0
      # not yet at the end of 'b':
      return -1
    elif j >= b.len:
      return 1
    inc i
    inc j

template cmpIgnoreCaseImpl*(caseSensitive: static bool = false) =
  # a, b are string or cstring
  var i = 0
  var m = min(a.len, b.len)
  while i < m:
    result = ord(toLowerAscii(a[i])) - ord(toLowerAscii(b[i]))
    if result != 0: return
    inc(i)
  result = a.len - b.len
