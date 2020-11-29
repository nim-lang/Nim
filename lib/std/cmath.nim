##[
Low level wrappers around C math functions.
]##

proc isnan*(x: float): bool {.importc: "isnan", header: "<math.h>".}
  # a generic like `x: SomeFloat` might work too if this is implemented via a C macro.
