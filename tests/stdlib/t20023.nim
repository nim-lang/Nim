import std/[tables, hashes, assertions]


let t = ()
var a = toTable({t:t})
del(a,t)
let b = default(typeof(a))

doAssert a==b , "tables are not equal"
doAssert hash(a) == hash(b), "table hashes are not equal"
