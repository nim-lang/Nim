discard """
  output: "23456"  
"""

template toSeq*(iter: expr): expr {.immediate.} =
  var result: seq[type(iter)] = @[]
  for x in iter: add(result, x)
  result
  
for x in items(toSeq(countup(2, 6))): 
  stdout.write(x)

import strutils

var y: type("a b c".split)
y = "xzy"



