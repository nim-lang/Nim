discard """
  output: '''success'''
"""

static:
  import algorithm
  
  var numArray = [1, 2, 3, 4, -1]
  numArray.sort(cmp)
  assert numArray == [-1, 1, 2, 3, 4]

  var str = "cba"
  str.sort(cmp)
  assert str == "abc"

echo "success"
