discard """
  output: "234"
"""

# bug #4432

import strutils

converter toInt(s: string): int =
  result = parseInt(s)

let x = (int)"234"
echo x
