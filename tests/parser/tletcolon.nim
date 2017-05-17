discard """
  output: '''boo
3
44 3
more body code
yes
yes'''
"""

template x(body): untyped =
  body
  44

template y(val, body): untyped =
  body
  val

proc mana =
  let foo = x:
    echo "boo"
  var foo2: int
  foo2 = y 3:
    echo "3"
  echo foo, " ", foo2

mana()
let other = x:
  echo "more body code"
  if true:
    echo "yes"
  else:
    echo "no"
let outer = y(5):
  echo "yes"
