discard """
  cmd: '''nim c --newruntime $file'''
  output: '''@[1]
@[116, 101, 115, 116]'''
"""

# bug #11018
discard cast[seq[uint8]](@[1])
discard cast[seq[uint8]]("test")
echo cast[seq[uint8]](@[1])
echo cast[seq[uint8]]("test")
