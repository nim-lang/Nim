# when defined case1
# iterator aimp[T](x: T): int = # ok
when defined case1:
  iterator aimp[T](x: T): int {.closure.} =
    discard

  for x in aimp[int](3):
    discard

when defined case2:
  iterator aimp(): int {.closure.} =
    discard

  # type T = typeof(aimp())
  for x in aimp():
    discard

when defined case3:
  block:
    {.define(nimCompilerDebug).}
    iterator aimp(): int {.closure.} =
      discard

    # type T = typeof(aimp())
    for x in aimp():
      discard
