discard """
  output: '''string 1
string 2
string 3
'''
"""
# bug #5532
import os, asyncfile, asyncdispatch

const F = "test_async.txt"

removeFile(F)
let f = openAsync(F, fmWrite)
var futs = newSeq[Future[void]]()
for i in 1..3:
  futs.add(f.write("string " & $i & "\n"))
waitFor(all(futs))
f.close()
echo readFile(F)
removeFile(F)
