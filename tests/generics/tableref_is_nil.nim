discard """
  output: "true"
"""

# bug #2221
import tables

var tblo: TableRef[string, int]
echo tblo == nil
