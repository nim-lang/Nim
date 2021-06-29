discard """
  cmd: '''nim c --gc:arc $file'''
  output: '''
showing original type, length, and contents seq[int] 1 @[42]
copy length and contents 1 @[42]
'''
"""

proc test() =
  var sq1 = @[42]
  echo "showing original type, length, and contents ", sq1.typeof, " ", sq1.len, " ", sq1
  doAssert cast[int](sq1[0].unsafeAddr) != 0
  var sq2 = sq1 # copy of original
  echo "copy length and contents ", sq2.len, " ", sq2
  doAssert cast[int](sq2[0].unsafeAddr) != 0
  doAssert cast[int](sq1[0].unsafeAddr) != 0

test()


#############################################
### bug 12820
import tables
var t = initTable[string, seq[ptr int]]()
discard t.hasKeyOrPut("f1", @[])


#############################################
### bug #12989
proc bug(start: (seq[int], int)) =
  let (s, i) = start

let input = @[0]
bug((input, 0))
