discard """
  output: "0123456789"
"""

# Test new countup

for i in 0 ..< 10'i64:
  stdout.write(i)
echo "\n"
