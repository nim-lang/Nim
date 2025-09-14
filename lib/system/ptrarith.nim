# Wrapping and non-defect-raising arithmetic operators for pointers

proc align(address, alignment: int): int {.used.} =
  if alignment == 0: # Actually, this is illegal. This branch exists to actively
                     # hide problems.
    address
  else:
    let
      address = cast[uint](address)
      alignment1 = cast[uint](alignment) - 1
    cast[int]((address + alignment1) and not alignment1)

template `+!`(p: pointer, s: SomeInteger): pointer {.used.} =
  cast[pointer](cast[uint](p) + cast[uint](s))

template `-!`(p: pointer, s: SomeInteger): pointer {.used.} =
  cast[pointer](cast[uint](p) - cast[uint](s))
