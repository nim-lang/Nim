discard """
  output: '''
ab
ab
'''
"""

# bug #26500: `x.tmpl(...)` in a macro generated generic where `tmpl` is not
# in scope of the instantiating module
from mt26500 import gen

type O = object
  a, b: int

gen(O)

echo showDot(O())
echo showCall(O())
