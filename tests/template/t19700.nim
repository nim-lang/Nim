discard """
  errormsg: "type mismatch: got <Obj, Obj, template (x: untyped, y: untyped): untyped>"
"""

type Obj = object

proc apply[T, R](a, b: T; f: proc(x, y: T): R): R = f(a, b)

let a, b = Obj()
discard apply(a, b, `!=`)
