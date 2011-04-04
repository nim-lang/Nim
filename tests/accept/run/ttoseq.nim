discard """
  output: "23456"  
"""

template toSeq*(iter: expr): expr =
  var result: seq[type(iter)] = @[]
  for x in iter: add(result, x)
  result
  
for x in items(toSeq(countup(2, 6))): 
  stdout.write(x)

