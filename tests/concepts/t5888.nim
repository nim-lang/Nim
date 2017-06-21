discard """
output: '''
true
true
true
f
0
'''
"""

import t5888lib/ca, t5888lib/opt

type LocalCA = ca.CA

proc f(c: CA) =
  echo "f"
  echo c.x

var o = new(Opt)

echo o is CA
echo o is LocalCA
echo o is ca.CA

o.f()

