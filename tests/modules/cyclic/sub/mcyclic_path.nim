import ../tcyclic_path {.cyclic.}

type
  Inner* = object
    back*: ref Outer

proc fb*(): int = 41
