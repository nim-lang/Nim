discard """
  output: "abcd"
"""

import tables

var x = initTable[int, string]()

x[2] = "ab"
x[5] = "cd"

echo x[2], x[5]
