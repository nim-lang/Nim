proc repr*(x: int): string {.magic: "IntToStr", noSideEffect.}
  ## repr for an integer argument. Returns `x`
  ## converted to a decimal string.

proc repr*(x: int64): string {.magic: "Int64ToStr", noSideEffect.}
  ## repr for an integer argument. Returns `x`
  ## converted to a decimal string.

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
  ##   assert $'c' == "c"

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

template repr(t: typedesc): string = $t

proc isNamedTuple(T: typedesc): bool =
  # Taken from typetraits.
  when T isnot tuple: result = false
  else:
    var t: T
    for name, _ in t.fieldPairs:
      when name == "Field0":
        return compiles(t.Field0)
      else:
        return true
    return false

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
  else:
    result = ""
  result.add '('
  var firstElement = true
  const isNamed = T is object or isNamedTuple(T)
  when not isNamed:
    var count = 0
  for name, value in fieldPairs(x):
    if not firstElement: result.add(", ")
    when isNamed:
      result.add(name)
      result.add(": ")
    else:
      count.inc
    when compiles($value):
      when value isnot string and value isnot seq and compiles(value.isNil):
        if value.isNil: result.add "nil"
        else: result.addQuoted(value)
      else:
        result.addQuoted(value)
      firstElement = false
    else:
      result.add("...")
      firstElement = false
  when not isNamed:
    if count == 1:
      result.add(',') # $(1,) should print as the semantically legal (1,)
  result.add(')')

proc repr*[T: (ref object)](x: T): string =
  ## Generic `repr` operator for tuples that is lifted from the components
  ## of `x`.
  if x == nil: return "nil"
  result = $typeof(x) & "("
  var firstElement = true
  for name, value in fieldPairs(x[]):
    if not firstElement: result.add(", ")
    result.add(name)
    result.add(": ")
    when compiles($value):
      when value isnot string and value isnot seq and compiles(value.isNil):
        if value.isNil: result.add "nil"
        else: result.addQuoted(value)
      else:
        result.addQuoted(value)
      firstElement = false
    else:
      result.add("...")
      firstElement = false
  result.add(')')

proc collectionToRepr[T](x: T, prefix, separator, suffix: string): string =
  result = prefix
  var firstElement = true
  for value in items(x):
    if firstElement:
      firstElement = false
    else:
      result.add(separator)

    when value isnot string and value isnot seq and compiles(value.isNil):
      # this branch should not be necessary
      if value.isNil:
        result.add "nil"
      else:
        result.addQuoted(value)
    else:
      result.addQuoted(value)
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
  result = $x.a
  result.add(" .. ")
  result.add($x.b)

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
