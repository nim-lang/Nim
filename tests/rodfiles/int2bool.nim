
{.overflowchecks: on.}

converter uglyToBool*(x: int): bool =
  {.Breakpoint.}
  result = x != 0
