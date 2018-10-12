import sugar, sequtils

let x = map(@[1, 2, 3], x => x+10)
assert x == @[11, 12, 13]

let y = map(@[(1,"a"), (2,"b"), (3,"c")], x => $x[0] & x[1])
assert y == @["1a", "2b", "3c"]

proc eatsTwoArgProc[T,S,U](a: T, b: S, f: proc(t: T, s: S): U): U =
  f(a,b)

let z = eatsTwoArgProc(1, "a", (t,s) => $t & s)
assert z == "1a"
