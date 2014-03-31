discard """
  file: "tnestedbreak.nim"
  output: "1\n2\n3\n4"
"""

# First variety
try:
  raise newException(EOS, "Problem")
except EOS:
  for y in [1, 2, 3]:
    discard
  try:
    discard
  except EOS:
    discard
echo "1"

# Second Variety
try:
  raise newException(EOS, "Problem")
except EOS:
  for y in [1, 2, 3]:
    discard
  for y in [1, 2, 3]:
    discard

echo "2"

# Third Variety
try:
  raise newException(EOS, "Problem")
except EOS:
  block:
    break

echo "3"

# Fourth Variety
block:
  try:
    raise newException(EOS, "Problem")
  except EOS:
    break

echo "4"