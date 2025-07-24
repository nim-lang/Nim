from std/private/digitsutils import addInt

template toLocation*(result: var string, file: string | cstring, line: int, col: int) =
  ## avoids spurious allocations
  # Hopefully this can be re-used everywhere so that if a user needs to customize,
  # it can be done in a single place.
  result.add file
  if line > 0:
    result.add "("
    addInt(result, line)
    if col > 0:
      result.add ", "
      addInt(result, col)
    result.add ")"

proc isNamedTuple(T: typedesc): bool {.magic: "TypeTrait".}

template tupleObjectDollar*[T: tuple | object](result: var string, x: T) =
  result = "("
  const isNamed = T is object or isNamedTuple(typeof(T))
  var count {.used.} = 0
  for name, value in fieldPairs(x):
    if count > 0: result.add(", ")
    when isNamed:
      result.add(name)
      result.add(": ")
    count.inc
    when compiles($value):
      when value isnot string and value isnot seq and compiles(value.isNil):
        if value.isNil: result.add "nil"
        else: result.addQuoted(value)
      else:
        result.addQuoted(value)
    else:
      result.add("...")
  when not isNamed:
    if count == 1:
      result.add(",") # $(1,) should print as the semantically legal (1,)
  result.add(")")
