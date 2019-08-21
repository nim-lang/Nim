discard """
  errormsg: "ambiguous identifier: 'range' -- use one of the following:"
  line: "13"
"""

import mrange

# bug #6965
type SomeObj = object
  s: set[int8]

# bug #6726
range()
