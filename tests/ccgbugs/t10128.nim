# bug #10128
let data = "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz"
var seq2 = newSeq[char](data.len)
for i in 0..<data.len:
  seq2[i] = data[i]

let c = '\128'

# case 1
doAssert data[c.int] == 'y'
doAssert seq2[c.int] == 'y'

proc play(x: openArray[char]) =
  doAssert x[c.int] == 'y'

# case2
play(data)
play(seq2)