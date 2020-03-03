discard """
output: '''
hallo40
1
2
'''
"""
# test for extremely strange bug

proc ack(x: int, y: int): int =
  if x != 0:
    if y != 5:
      return y
    return x
  return x+y

proc gen[T](a: T) =
  write(stdout, a)


gen("hallo")
write(stdout, ack(5, 4))
#OUT hallo4

# bug #1442
let h=3
for x in 0 ..< h.int:
  echo x
