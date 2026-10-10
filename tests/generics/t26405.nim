discard """
  matrix: "--mm:orc; --mm:arc"
  output: '''
1
destroy A
[1]
1.5
destroy B
[1, 2, 3, 4, 5, 6, 7, 8]
'''
"""

# bug #26405: types local to a generic proc must not be shared by instances
# that are created in different modules.

import m26405a, m26405b

type B = object
proc `=destroy`(x: B) = echo "destroy B"

a()
verifyObj[float]()
verifyDistinct(B)
verifyStatic[8]()
