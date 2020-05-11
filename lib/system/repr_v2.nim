proc isNamedTuple(T: typedesc): bool {.magic: "TypeTrait".}
  ## imported from typetraits

proc distinctBase(T: typedesc): typedesc {.magic: "TypeTrait".}
  ## imported from typetraits

proc repr*(x: NimNode): string {.magic: "Repr", noSideEffect.}

proc repr*(x: int): string {.magic: "IntToStr", noSideEffect.}
  ## repr for an integer argument. Returns `x`
  ## converted to a decimal string.

proc repr*(x: int64): string {.magic: "Int64ToStr", noSideEffect.}
  ## repr for an integer argument. Returns `x`
  ## converted to a decimal string.

proc repr*(x: uint64): string {.noSideEffect.} =
  ## repr for an unsigned integer argument. Returns `x`
  ## converted to a decimal string.
  $x #Calls `$` from system/strmantle.nim

proc repr*(x: float): string {.magic: "FloatToStr", noSideEffect.}
  ## repr for a float argument. Returns `x`
  ## converted to a decimal string.

proc repr*(x: bool): string {.magic: "BoolToStr", noSideEffect.}
  ## repr for a boolean argument. Returns `x`
  ## converted to the string "false" or "true".

proc repr*(x: char): string {.magic: "CharToStr", noSideEffect.}
  ## repr for a character argument. Returns `x`
  ## converted to a string.
  ##
  ## .. code-block:: Nim
  ##   assert repr('c') == "c"

proc repr*(x: cstring): string {.magic: "CStrToStr", noSideEffect.}
  ## repr for a CString argument. Returns `x`
  ## converted to a string.

proc repr*(x: string): string {.magic: "StrToStr", noSideEffect.}
  ## repr for a string argument. Returns `x`
  ## as it is. This operator is useful for generic code, so
  ## that ``$expr`` also works if ``expr`` is already a string.

proc repr*[Enum: enum](x: Enum): string {.magic: "EnumToStr", noSideEffect.}
  ## repr for an enumeration argument. This works for
  ## any enumeration type thanks to compiler magic.
  ##
  ## If a `repr` operator for a concrete enumeration is provided, this is
  ## used instead. (In other words: *Overwriting* is possible.)

proc repr*(p: pointer): string =
  ## repr of pointer as its hexadecimal value
  if p == nil:
    result = "nil"
  else:
    when nimvm:
      result = "ptr"
    else:
      const HexChars = "0123456789ABCDEF"
      const len = sizeof(pointer) * 2
      var n = cast[uint](p)
      result = newString(len)
      for j in countdown(len-1, 0):
        result[j] = HexChars[n and 0xF]
        n = n shr 4

template repr*(x: distinct): string =
  repr(distinctBase(typeof(x))(x))

template repr*(t: typedesc): string = $t

proc reprObject[T: tuple|object](res: var string, x: T) =
  res.add '('
  var firstElement = true
  const isNamed = T is object or isNamedTuple(T)
  when not isNamed:
    var count = 0
  for name, value in fieldPairs(x):
    if not firstElement: res.add(", ")
    when isNamed:
      res.add(name)
      res.add(": ")
    else:
      count.inc
    res.add repr(value)
    firstElement = false
  when not isNamed:
    if count == 1:
      res.add(',') # $(1,) should print as the semantically legal (1,)
  res.add(')')


proc repr*[T: tuple|object](x: T): string =
  ## Generic `repr` operator for tuples that is lifted from the components
  ## of `x`. Example:
  ##
  ## .. code-block:: Nim
  ##   $(23, 45) == "(23, 45)"
  ##   $(a: 23, b: 45) == "(a: 23, b: 45)"
  ##   $() == "()"
  when T is object:
    result = $typeof(x)
  reprObject(result, x)

proc repr*[T](x: ref T | ptr T): string =
  if isNil(x): return "nil"
  when T is object:
    result = $typeof(x)
    reprObject(result, x[])
  else:
    result = when typeof(x) is ref: "ref " else: "ptr "
    result.add repr(x[])

proc collectionToRepr[T](x: T, prefix, separator, suffix: string): string =
  result = prefix
  var firstElement = true
  for value in items(x):
    if firstElement:
      firstElement = false
    else:
      result.add(separator)
    result.add repr(value)
  result.add(suffix)

proc repr*[T](x: set[T]): string =
  ## Generic `repr` operator for sets that is lifted from the components
  ## of `x`. Example:
  ##
  ## .. code-block:: Nim
  ##   ${23, 45} == "{23, 45}"
  collectionToRepr(x, "{", ", ", "}")

proc repr*[T](x: seq[T]): string =
  ## Generic `repr` operator for seqs that is lifted from the components
  ## of `x`. Example:
  ##
  ## .. code-block:: Nim
  ##   $(@[23, 45]) == "@[23, 45]"
  collectionToRepr(x, "@[", ", ", "]")

proc repr*[T, U](x: HSlice[T, U]): string =
  ## Generic `repr` operator for slices that is lifted from the components
  ## of `x`. Example:
  ##
  ## .. code-block:: Nim
  ##  $(1 .. 5) == "1 .. 5"
  result = repr(x.a)
  result.add(" .. ")
  result.add(repr(x.b))

proc repr*[T, IDX](x: array[IDX, T]): string =
  ## Generic `repr` operator for arrays that is lifted from the components.
  collectionToRepr(x, "[", ", ", "]")

proc repr*[T](x: openArray[T]): string =
  ## Generic `repr` operator for openarrays that is lifted from the components
  ## of `x`. Example:
  ##
  ## .. code-block:: Nim
  ##   $(@[23, 45].toOpenArray(0, 1)) == "[23, 45]"
  collectionToRepr(x, "[", ", ", "]")
