discard """
  errormsg: "isOdd(3) can have an unlisted effect: RootEffect"
  file: "tunsound_tags.nim"
"""

# like tunsound_raises.nim, for `.tags`:
import effects/meven_tags {.cyclic.}

proc isOdd*(n: int): bool = n != 0 and isEven(n - 1)
proc t*(): bool {.tags: [].} = isOdd(3)
echo t()
