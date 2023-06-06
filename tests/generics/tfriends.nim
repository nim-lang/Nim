discard """
  output: "3"
"""

# Tests that a generic instantiation from a different module may access
# private object fields:

import mfriends

echo gen[int]()

