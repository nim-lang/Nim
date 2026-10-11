discard """
  targets: "c cpp"
  output: '''
nil
called 3
'''
"""

# bug #5785: casts between closure types
var p1: proc(a: int) {.closure.}
var p2 = cast[proc() {.closure.}](p1)
echo (if p2 == nil: "nil" else: "not nil")

proc outer =
  var x = 3
  let f = proc(a: int) = echo "called ", x
  let g = cast[proc(a: int, b: int = 0) {.closure.}](f)
  let h = cast[proc(a: int) {.closure.}](g)
  h(1)

outer()
