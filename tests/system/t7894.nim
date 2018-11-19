discard """
"""

const size = 250000000
var saved = newSeq[seq[int8]]()

for i in 0..22:
  # one of these is 0.25GB.
  #echo i
  var x = newSeq[int8](size)
  saved.add(x)

for x in saved:
  #echo x.len
  doAssert x.len == size
