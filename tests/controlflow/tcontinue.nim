discard """
  output: "came here"
"""

var i = 0
while i < 400:

  if i == 10: break
  elif i == 3: 
    inc i
    continue
  inc i

var f = "failure"
var j = 0
while j < 300:
  for x in 0..34:
    if j < 300: continue
    if x == 10: 
      echo "failure: should never happen"
      break
  f = "came here"
  break

if i == 10:
  echo f
else:
  echo "failure"
