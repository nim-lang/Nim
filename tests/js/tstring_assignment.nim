discard """
  output: '''true
asdfasekjkler'''
"""

# bug #4471
when true:
  let s1 = "123"
  var s2 = s1
  s2.setLen(0)
  # fails - s1.len == 0
  echo s1.len == 3

# bug #4470
proc main(s: cstring): string =
  result = newString(0)
  for i in 0..<s.len:
    if s[i] >= 'a' and s[i] <= 'z':
      result.add s[i]

echo main("asdfasekjkleräöü")
