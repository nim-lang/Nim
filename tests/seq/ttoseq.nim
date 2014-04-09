discard """
  output: "2345623456"
"""

import sequtils

for x in toSeq(countup(2, 6)): 
  stdout.write(x)
for x in items(toSeq(countup(2, 6))): 
  stdout.write(x)

import strutils

var y: type("a b c".split)
y = "xzy"



