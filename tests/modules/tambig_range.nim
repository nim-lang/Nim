discard """
  errormsg: "ambiguous identifier: 'range' --use system.range or mrange.range"
  line: 9
"""

# bug #6726
import mrange

range()
