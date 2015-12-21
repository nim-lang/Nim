discard """
  output: "abef"
"""

import tables

var x = initTable[int, string]()

x[2] = "ab"
x[5] = "ef"

echo x[2], x[5]
