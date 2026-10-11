discard """
  targets: "c cpp"
  output: '''
3 {'\x00', '\x01'}
[2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
{1, 9}
'''
"""

# bug #3540: casts to and from sets that are C arrays
let
  a = {'\0', '\1'}
  b = cast[uint8](a)
  c = cast[set[char]](b)
echo b, " ", c

type S = set[0..127]
let s: S = {1, 9}
let d = cast[array[16, uint8]](s)
echo d
echo cast[S](d)
