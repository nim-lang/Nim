import sequtils
let xs: seq[tuple[key: string, val: seq[string]]] = @[("foo", @["bar"])]

let maps = xs.map(
  proc(x: auto): tuple[typ: string, maps: seq[string]] =
    (x.key, x.val.map(proc(x: string): string = x)))