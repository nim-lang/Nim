template spliceImpl(s, a, L, b: untyped): untyped =
  # make room for additional elements or cut:
  var shift = b.len - max(0,L)  # ignore negative slice size
  var newLen = s.len + shift
  if shift > 0:
    # enlarge:
    setLen(s, newLen)
    for i in countdown(newLen-1, a+b.len): movingCopy(s[i], s[i-shift])
  else:
    for i in countup(a+b.len, newLen-1): movingCopy(s[i], s[i-shift])
    # cut down:
    setLen(s, newLen)
  # fill the hole:
  for i in 0 ..< b.len: s[a+i] = b[i]

proc `[]`*[T, U: Ordinal](s: string, x: HSlice[T, U]): string {.inline.} =
  ## Slice operation for strings.
  ## Returns the inclusive range `[s[x.a], s[x.b]]`:
  ##   ```
  ##   var s = "abcdef"
  ##   assert s[1..3] == "bcd"
  ##   ```
  let a = s ^^ x.a
  let L = (s ^^ x.b) - a + 1
  result = newString(L)
  for i in 0 ..< L: result[i] = s[i + a]

proc `[]=`*[T, U: Ordinal](s: var string, x: HSlice[T, U], b: string) =
  ## Slice assignment for strings.
  ##
  ## If `b.len` is not exactly the number of elements that are referred to
  ## by `x`, a `splice`:idx: is performed:
  ##
  runnableExamples:
    var s = "abcdefgh"
    s[1 .. ^2] = "xyz"
    assert s == "axyzh"

  var a = s ^^ x.a
  var L = (s ^^ x.b) - a + 1
  if L == b.len:
    for i in 0..<L: s[i+a] = b[i]
  else:
    spliceImpl(s, a, L, b)

proc `[]`*[Idx, T; U, V: Ordinal](a: array[Idx, T], x: HSlice[U, V]): seq[T] =
  ## Slice operation for arrays.
  ## Returns the inclusive range `[a[x.a], a[x.b]]`:
  ##   ```
  ##   var a = [1, 2, 3, 4]
  ##   assert a[0..2] == @[1, 2, 3]
  ##   ```
  let xa = a ^^ x.a
  let L = (a ^^ x.b) - xa + 1
  result = newSeq[T](L)
  for i in 0..<L: result[i] = a[Idx(i + xa)]

proc `[]=`*[Idx, T; U, V: Ordinal](a: var array[Idx, T], x: HSlice[U, V], b: openArray[T]) =
  ## Slice assignment for arrays.
  ##   ```
  ##   var a = [10, 20, 30, 40, 50]
  ##   a[1..2] = @[99, 88]
  ##   assert a == [10, 99, 88, 40, 50]
  ##   ```
  let xa = a ^^ x.a
  let L = (a ^^ x.b) - xa + 1
  if L == b.len:
    for i in 0..<L: a[Idx(i + xa)] = b[i]
  else:
    sysFatal(RangeDefect, "different lengths for slice assignment")

proc `[]`*[T; U, V: Ordinal](s: openArray[T], x: HSlice[U, V]): seq[T] =
  ## Slice operation for sequences.
  ## Returns the inclusive range `[s[x.a], s[x.b]]`:
  ##   ```
  ##   var s = @[1, 2, 3, 4]
  ##   assert s[0..2] == @[1, 2, 3]
  ##   ```
  let a = s ^^ x.a
  let L = (s ^^ x.b) - a + 1
  newSeq(result, L)
  for i in 0 ..< L: result[i] = s[i + a]

proc `[]=`*[T; U, V: Ordinal](s: var seq[T], x: HSlice[U, V], b: openArray[T]) =
  ## Slice assignment for sequences.
  ##
  ## If `b.len` is not exactly the number of elements that are referred to
  ## by `x`, a `splice`:idx: is performed.
  runnableExamples:
    var s = @"abcdefgh"
    s[1 .. ^2] = @"xyz"
    assert s == @"axyzh"

  let a = s ^^ x.a
  let L = (s ^^ x.b) - a + 1
  if L == b.len:
    for i in 0 ..< L: s[i+a] = b[i]
  else:
    spliceImpl(s, a, L, b)
