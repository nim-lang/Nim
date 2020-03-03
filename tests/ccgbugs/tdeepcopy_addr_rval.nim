discard """
  output: "3"
"""

# issue 5166

type
  Test = ref object
    x: int

let x = Test(x: 3)
let p = cast[pointer](x)

var v: Test
deepCopy(v, cast[Test](p))
echo v.x
