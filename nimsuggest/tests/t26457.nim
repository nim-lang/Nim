# bug #26457: after recompiling a module the VM ran stale compile-time procs
import fixtures/m26457

const n = count(@[1, 2, 3])

proc p1(): string {.compileTime.} = "s1"
const c1 = (let f = p1; f())
proc p2(): float {.compileTime.} = 2.0
const c2 = (let f = p2; f())
proc p3(): int {.compileTime.} = 3
const c3 = (let f = p3; f())
proc p4(): string {.compileTime.} = "s4"
const c4 = (let f = p4; f())

echo n, c1, c2, c3, c4

proc foo*(): int = 1

discard """
$nimsuggest --tester --v4 $file
>def $file:17:6
def;;skProc;;t26457.foo;;*;;$file;;17;;5;;""
>chk $file
*
>changed $file
>chk $file
*
>def $file:17:6
def;;skProc;;t26457.foo;;*;;$file;;17;;5;;""
"""
