import tables, random
var t = initOrderedTable[int,string]()

# this tests issue #5917
var data = newSeq[int]()
for i in 0..<1000:
  var x = random(1000)
  if x notin t: data.add(x)
  t[x] = "meh"

# this checks that keys are re-inserted
# in order when table is enlarged.
var i = 0
for k, v in t:
  doAssert(k == data[i])
  doAssert(v == "meh")
  inc(i)

