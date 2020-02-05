func `$`*(x: int): string {.magic: "IntToStr".}
  ## The stringify operator for an integer argument. Returns `x`
  ## converted to a decimal string. ``$`` is Nim's general way of
  ## spelling `toString`:idx:.

func `$`*(x: int64): string {.magic: "Int64ToStr".}
  ## The stringify operator for an integer argument. Returns `x`
  ## converted to a decimal string.

func `$`*(x: float): string {.magic: "FloatToStr".}
  ## The stringify operator for a float argument. Returns `x`
  ## converted to a decimal string.

func `$`*(x: bool): string {.magic: "BoolToStr".}
  ## The stringify operator for a boolean argument. Returns `x`
  ## converted to the string "false" or "true".

func `$`*(x: char): string {.magic: "CharToStr".}
  ## The stringify operator for a character argument. Returns `x`
  ## converted to a string.
  ##
  ## .. code-block:: Nim
  ##   assert $'c' == "c"

func `$`*(x: cstring): string {.magic: "CStrToStr".}
  ## The stringify operator for a CString argument. Returns `x`
  ## converted to a string.

func `$`*(x: string): string {.magic: "StrToStr".}
  ## The stringify operator for a string argument. Returns `x`
  ## as it is. This operator is useful for generic code, so
  ## that ``$expr`` also works if ``expr`` is already a string.

func `$`*[Enum: enum](x: Enum): string {.magic: "EnumToStr".}
  ## The stringify operator for an enumeration argument. This works for
  ## any enumeration type thanks to compiler magic.
  ##
  ## If a ``$`` operator for a concrete enumeration is provided, this is
  ## used instead. (In other words: *Overwriting* is possible.)

proc `$`*(t: typedesc): string {.magic: "TypeTrait".}
  ## Returns the name of the given type.
  ##
  ## For more procedures dealing with ``typedesc``, see
  ## `typetraits module <typetraits.html>`_.
  ##
  ## .. code-block:: Nim
  ##   doAssert $(type(42)) == "int"
  ##   doAssert $(type("Foo")) == "string"
  ##   static: doAssert $(type(@['A', 'B'])) == "seq[char]"

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

proc `$`*[T: tuple|object](x: T): string =
  ## Generic ``$`` operator for tuples that is lifted from the components
  ## of `x`. Example:
  ##
  ## .. code-block:: Nim
  ##   $(23, 45) == "(23, 45)"
  ##   $(a: 23, b: 45) == "(a: 23, b: 45)"
  ##   $() == "()"
  result = "("
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
      result.add(",") # $(1,) should print as the semantically legal (1,)
  result.add(")")


proc collectionToString[T](x: T, prefix, separator, suffix: string): string =
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

func `$`*[T](x: set[T]): string =
  ## Generic ``$`` operator for sets that is lifted from the components
  ## of `x`. Example:
  ##
  ## .. code-block:: Nim
  ##   ${23, 45} == "{23, 45}"
  collectionToString(x, "{", ", ", "}")

func `$`*[T](x: seq[T]): string =
  ## Generic ``$`` operator for seqs that is lifted from the components
  ## of `x`. Example:
  ##
  ## .. code-block:: Nim
  ##   $(@[23, 45]) == "@[23, 45]"
  collectionToString(x, "@[", ", ", "]")

func `$`*[T, U](x: HSlice[T, U]): string =
  ## Generic ``$`` operator for slices that is lifted from the components
  ## of `x`. Example:
  ##
  ## .. code-block:: Nim
  ##  $(1 .. 5) == "1 .. 5"
  result = $x.a
  result.add(" .. ")
  result.add($x.b)


when not defined(nimNoArrayToString):
  func `$`*[T, IDX](x: array[IDX, T]): string =
    ## Generic ``$`` operator for arrays that is lifted from the components.
    collectionToString(x, "[", ", ", "]")

func `$`*[T](x: openArray[T]): string =
  ## Generic ``$`` operator for openarrays that is lifted from the components
  ## of `x`. Example:
  ##
  ## .. code-block:: Nim
  ##   $(@[23, 45].toOpenArray(0, 1)) == "[23, 45]"
  collectionToString(x, "[", ", ", "]")
