discard """
  output: '''
123
123
4
m4
'''
"""

# bug #13450: the branches of `when nimvm` are typed like those of an `if`
proc m2(): int =
  when nimvm: raiseAssert "x"
  else: 123
echo m2()
proc m3(): int =
  when nimvm: 4
  else: 123
echo m3()
const k = m3()
echo k
proc m4() =
  when nimvm: discard
  else: echo "m4"
m4()
