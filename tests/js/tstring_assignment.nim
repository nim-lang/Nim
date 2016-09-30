discard """
  output: '''true'''
"""

# bug #4471
when true:
  let s1 = "123"
  var s2 = s1
  s2.setLen(0)
  # fails - s1.len == 0
  echo s1.len == 3
