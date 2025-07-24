import std/assertions

let a = 0
let b = if false: -1 else: a
doAssert b == 0

let c: range[0..high(int)] = 0
let d = if false: -1 else: c

doAssert d == 0
