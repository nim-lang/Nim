discard """
  output: '''
NONE
'''
"""

# issue #24887

macro foo(x: typed) =
  result = x

foo:
  type
    Flags64 = distinct uint64

  const NONE = Flags64(0'u64)
  const MAX: Flags64 = Flags64(uint64.high)

  proc `$`(x: Flags64): string =
    case x:
    of NONE:
      return "NONE"
    of MAX:
      return "MAX"
    else:
      return "UNKNOWN"

  let okay = Flags64(128'u64)

  echo $NONE
