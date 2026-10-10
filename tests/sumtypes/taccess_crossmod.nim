discard """
  errormsg: "field 'val' can only be accessed in a pattern matching `case` branch"
  line: 9
"""

import msumtypes

let a = some(1)
echo a.val
