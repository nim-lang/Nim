discard """
  output: '''foo
true'''
"""

converter p(i: int): bool = return i != 0

if 1:
  echo if 4: "foo" else: "barr"
while 0:
  echo "bar"

var a: array[3, bool]
a[0] = 3
echo a[0]
