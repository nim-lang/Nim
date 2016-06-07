
# bug #3794


import options

proc getRef*(): Option[int] =
  return none(int)

proc getChild*() =
  let iter = iterator (): int {.closure.} =
    let reference = getRef()
