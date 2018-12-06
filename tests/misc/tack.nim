discard """
  output: "125"
"""
# the Ackermann function

proc ack(x, y: int): int =
  if x != 0:
    if y != 0:
      return ack(x-1, ack(x, y-1))
    return ack(x-1, 1)
  else:
    return y + 1
#  if x == 0: return y + 1
#  elif y == 0: return ack(x-1, 1)
#  else: return ack(x-1, ack(x, y-1))

# echo(ack(0, 0))
write(stdout, ack(3, 4)) #OUT 125
write stdout, "\n"
