discard """
  output: "1"
"""

var c = '\0'
while true:
  if c == '\xFF': break
  inc c

echo "1"
