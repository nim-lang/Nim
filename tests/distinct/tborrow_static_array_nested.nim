block:
  type
    StaticInner[N: static[int]] = distinct array[N, int]
    StaticOuter[N: static[int]] = distinct StaticInner[N]

  proc `[]`[N: static[int]](s: StaticOuter[N], i: int): int {.borrow.}

  var s: StaticOuter[3]
  discard s[0]
