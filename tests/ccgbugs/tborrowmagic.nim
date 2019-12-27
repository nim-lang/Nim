type
  Bytes = distinct seq[byte]

proc add(x: var Bytes; b: byte) {.borrow.}
var x = @[].Bytes
x.add(42)
let base = cast[seq[byte]](x)
doAssert base.len == 1 and base[0] == 42
