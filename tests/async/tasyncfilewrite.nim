discard """
  output: '''string 1
string 2
string 3'''
"""
# bug #5532
import os, asyncfile, asyncdispatch

removeFile("test.txt")
let f = openAsync("test.txt", fmWrite)
var futs = newSeq[Future[void]]()
for i in 1..3:
  futs.add(f.write("string " & $i & "\n"))
waitFor(all(futs))
f.close()
echo readFile("test.txt")

