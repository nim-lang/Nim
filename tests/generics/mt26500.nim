import std/macros

template withPairs*(x: auto, k: untyped, body: untyped) =
  for kk, v in fieldPairs(x):
    const k {.inject.} = kk
    body

macro gen*(T: untyped): untyped =
  quote do:
    func showDot[t: `T`](x: t): string =
      x.withPairs(key):
        result &= key
    func showCall[t: `T`](x: t): string =
      withPairs(x, key):
        result &= key
