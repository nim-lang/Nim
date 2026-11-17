discard """
  targets: "c cpp js"
  output: '''
false
true
'''
"""

# bug #12786: computed goto with a `bool` selector
proc test(a: bool) =
  var a = a
  var n = 0
  while true:
    {.computedGoto.}
    case a
    of false:
      echo "false"
      a = true
    of true:
      echo "true"
      inc n
      if n == 1: break
test(false)
