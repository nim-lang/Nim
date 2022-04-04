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
