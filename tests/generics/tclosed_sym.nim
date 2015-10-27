discard """
  output: "TEST2"
"""

# bug #2664

import mclosed_sym

proc same(r:R, d:int) = echo "TEST1"

doIt(Data[int](d:123), R())
