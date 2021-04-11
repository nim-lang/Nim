# proc `$`(x: int): string {.magic: "IntToStr", noSideEffect.}
proc toString(x: int): string {.magic: "IntToStr", noSideEffect.}

template toLocation*(result: var string, file: string | cstring, line: int, col: int) =
  ## avoids spurious allocations
  # Hopefully this can be re-used everywhere so that if a user needs to customize,
  # it can be done in a single place.
  result.add file
  if line > 0:
    result.add "("
    # simplify this after moving moving `include strmantle` above import assertions`
    when declared(addInt): result.addInt line
    else: result.add toString(line)
    if col > 0:
      result.add ", "
      when declared(addInt): result.addInt col
      else: result.add toString(col)
    result.add ")"
