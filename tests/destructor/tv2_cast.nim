discard """
  cmd: '''nim c --newruntime $file'''
  output: '''@[1]
@[116, 101, 115, 116]
test
@[1953719668, 875770417]'''
"""

# bug #11018
discard cast[seq[uint8]](@[1])
discard cast[seq[uint8]]("test")
echo cast[seq[uint8]](@[1])
echo cast[seq[uint8]]("test")

discard cast[seq[string]](@[116'u8, 101, 115, 116])
echo cast[seq[string]](@[116'u8, 101, 115, 116])
var a = cast[seq[uint32]]("test1234")
a.setLen(2)
echo a
