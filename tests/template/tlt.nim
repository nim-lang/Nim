
import mlt
# bug #4564
type Bar* = ref object of RootObj
proc foo(a: Bar): int = 0
var a: Bar
let b = a.foo() > 0
