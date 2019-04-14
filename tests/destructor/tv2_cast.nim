discard """
  cmd: '''nim c --newruntime $file'''
"""

# bug #11018
discard cast[seq[uint8]](@[1])
discard cast[seq[uint8]]("test")
discard cast[seq[uint8]]([1])
