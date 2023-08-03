discard """
  cmd: '''nim c --gc:refc -r $file'''
"""
const Memo = 100 * 1024

proc fff(v: sink string): iterator(): char =
  return iterator(): char =
    for c in v:
      yield c

var tmp = newString(Memo)

let iter = fff(move(tmp))

while true:
  let v = iter()
  if finished(iter):
    break

doAssert getOccupiedMem() < Memo * 3
