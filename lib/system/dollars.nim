proc `$`*(x: int): string {.magic: "IntToStr", noSideEffect.}
  ## The stringify operator for an integer argument. Returns `x`
  ## converted to a decimal string. ``$`` is Nim's general way of
  ## spelling `toString`:idx:.

proc `$`*(x: int64): string {.magic: "Int64ToStr", noSideEffect.}
  ## The stringify operator for an integer argument. Returns `x`
  ## converted to a decimal string.

proc `$`*(x: float): string {.magic: "FloatToStr", noSideEffect.}
  ## The stringify operator for a float argument. Returns `x`
  ## converted to a decimal string.

proc `$`*(x: bool): string {.magic: "BoolToStr", noSideEffect.}
  ## The stringify operator for a boolean argument. Returns `x`
  ## converted to the string "false" or "true".

proc `$`*(x: char): string {.magic: "CharToStr", noSideEffect.}
  ## The stringify operator for a character argument. Returns `x`
  ## converted to a string.
  ##
  ## .. code-block:: Nim
  ##   assert $'c' == "c"

proc `$`*(x: cstring): string {.magic: "CStrToStr", noSideEffect.}
  ## The stringify operator for a CString argument. Returns `x`
  ## converted to a string.

proc `$`*(x: string): string {.magic: "StrToStr", noSideEffect.}
  ## The stringify operator for a string argument. Returns `x`
  ## as it is. This operator is useful for generic code, so
  ## that ``$expr`` also works if ``expr`` is already a string.

proc `$`*[Enum: enum](x: Enum): string {.magic: "EnumToStr", noSideEffect.}
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

when defined(nimHasIsNamedTuple):
  proc isNamedTuple(T: typedesc): bool {.magic: "TypeTrait".}
else:
  # for bootstrap; remove after release 1.2
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

type
  SomePointer = ptr | ref | pointer

template typeLoopsBack[T,U](obj: T; field: U): bool #[{.magic: "typeLoopsback".}]# =
  ## Is substituted with `true`, if `U` or any of its recursive
  ## members are of type `T`.  This magic is inteded to be used to
  ## test if the `field` of `obj` can safely be printed without
  ## running into a cycle and therefore infinite recursion.
  false

proc `$`*[T: tuple|object](x: T): string =
  ## Generic ``$`` operator for tuples that is lifted from the components
  ## of `x`. Example:
  ##
  ## .. code-block:: Nim
  ##   $(23, 45) == "(23, 45)"
  ##   $(a: 23, b: 45) == "(a: 23, b: 45)"
  ##   $() == "()"
  result = "("
  const isNamed = x is object or isNamedTuple(T)
  var count = 0
  for name, value in fieldPairs(x):
    if count != 0:
      result.add(", ")
    if isNamed:
      result.add(name)
      result.add(": ")

    when typeLoopsBack(x, value):
      when value is SomePointer:
        if value == typeof(value)(nil):
          # nil can always be printed safely
          result.add "nil"
        else:
          result.add("...")
      else:
        # value may have a cycle, don't print it.
        result.add "..."
    else:
      result.addQuoted(value)

    inc count
  if not isNamed and count == 1:
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

    when value is SomePointer:
      # this branch should not be necessary
      if value.isNil:
        result.add "nil"
      else:
        result.addQuoted(value)
    else:
      result.addQuoted(value)
  result.add(suffix)

proc `$`*[T](x: set[T]): string =
  ## Generic ``$`` operator for sets that is lifted from the components
  ## of `x`. Example:
  ##
  ## .. code-block:: Nim
  ##   ${23, 45} == "{23, 45}"
  collectionToString(x, "{", ", ", "}")

proc `$`*[T](x: seq[T]): string =
  ## Generic ``$`` operator for seqs that is lifted from the components
  ## of `x`. Example:
  ##
  ## .. code-block:: Nim
  ##   $(@[23, 45]) == "@[23, 45]"
  collectionToString(x, "@[", ", ", "]")

proc `$`*[T, U](x: HSlice[T, U]): string =
  ## Generic ``$`` operator for slices that is lifted from the components
  ## of `x`. Example:
  ##
  ## .. code-block:: Nim
  ##  $(1 .. 5) == "1 .. 5"
  result = $x.a
  result.add(" .. ")
  result.add($x.b)


when not defined(nimNoArrayToString):
  proc `$`*[T, IDX](x: array[IDX, T]): string =
    ## Generic ``$`` operator for arrays that is lifted from the components.
    collectionToString(x, "[", ", ", "]")

proc `$`*[T](x: openArray[T]): string =
  ## Generic ``$`` operator for openarrays that is lifted from the components
  ## of `x`. Example:
  ##
  ## .. code-block:: Nim
  ##   $(@[23, 45].toOpenArray(0, 1)) == "[23, 45]"
  collectionToString(x, "[", ", ", "]")

proc `$`*[T: ref](arg: T): string = $arg[]

proc distinctBase(T: typedesc): typedesc {.magic: "TypeTrait".}

proc `$`*[T: distinct](arg: T): string =
  $distinctBase(T)(arg)
