discard """
  output: "1\n2\n3\n4"
"""

# First variety
try:
  raise newException(OSError, "Problem")
except OSError:
  for y in [1, 2, 3]:
    discard
  try:
    discard
  except OSError:
    discard
echo "1"

# Second Variety
try:
  raise newException(OSError, "Problem")
except OSError:
  for y in [1, 2, 3]:
    discard
  for y in [1, 2, 3]:
    discard

echo "2"

# Third Variety
try:
  raise newException(OSError, "Problem")
except OSError:
  block label:
    break label

echo "3"

# Fourth Variety
block label:
  try:
    raise newException(OSError, "Problem")
  except OSError:
    break label

echo "4"
