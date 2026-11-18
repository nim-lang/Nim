discard """
  output: '''
1.0
2.5
3
'''
"""

# bug #4007: an imported `addr` overload must be considered
import m4007

proc someFun(v: ptr float) = echo v[]

var modelDiffuse = vec4[float](1.0, 0.8, 0.8, 1.0)
modelDiffuse.stuff
someFun(modelDiffuse.addr)

var f = 2.5
someFun(f.addr)

type O = object
  x: int
var o = O(x: 3)
let p = addr(o.x)
echo p[]
