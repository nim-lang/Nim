func toLowerAscii*(c: char): char {.inline.} =
  if c in {'A'..'Z'}:
    result = chr(ord(c) + (ord('a') - ord('A')))
  else:
    result = c

template firstCharCaseSensitiveImpl[T: string | cstring](a, b: T, aLen, bLen: int) =
  if aLen == 0 or bLen == 0:
    return aLen - bLen
  if a[0] != b[0]: return ord(a[0]) - ord(b[0])

template cmpIgnoreStyleImpl*[T: string | cstring](a, b: T,
            firstCharCaseSensitive: static bool = false) =
  let aLen = a.len
  let bLen = b.len
  var i = 0
  var j = 0
  when firstCharCaseSensitive:
    firstCharCaseSensitiveImpl(a, b, aLen, bLen)
    inc i
    inc j
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

template cmpIgnoreCaseImpl*[T: string | cstring](a, b: T,
        firstCharCaseSensitive: static bool = false) =
  let aLen = a.len
  let bLen = b.len
  var i = 0
  when firstCharCaseSensitive:
    firstCharCaseSensitiveImpl(a, b, aLen, bLen)
    inc i
  var m = min(aLen, bLen)
  while i < m:
    result = ord(toLowerAscii(a[i])) - ord(toLowerAscii(b[i]))
    if result != 0: return
    inc i
  result = aLen - bLen

template startsWithImpl*[T: string | cstring](s, prefix: T) =
  let prefixLen = prefix.len
  let sLen = s.len
  var i = 0
  while true:
    if i >= prefixLen: return true
    if i >= sLen or s[i] != prefix[i]: return false
    inc(i)

template endsWithImpl*[T: string | cstring](s, suffix: T) =
  let suffixLen = suffix.len
  let sLen = s.len
  var i = 0
  var j = sLen - suffixLen
  while i+j >= 0 and i+j < sLen:
    if s[i+j] != suffix[i]: return false
    inc(i)
  if i >= suffixLen: return true


func cmpNimIdentifier*[T: string | cstring](a, b: T): int {.noSideEffect.} =
  cmpIgnoreStyleImpl(a, b, true)
