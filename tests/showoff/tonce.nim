discard """
  output: '''first call of p
some call of p
new instantiation
some call of p'''
"""

template once(body) =
  var x {.global.} = false
  if not x:
    x = true
    body

proc p() =
  once:
    echo "first call of p"
  echo "some call of p"

p()
once:
  echo "new instantiation"
p()
