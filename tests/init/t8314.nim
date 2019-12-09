discard """
  nimout: '''
t8314.nim(14, 7) Hint: BEGIN [User]
t8314.nim(25, 7) Hint: END [User]
  '''

output: '''
1
1
1
'''
"""

{.hint: "BEGIN".}
proc foo(x: range[1..10]) =
  block:
    var (y,) = (x,)
    echo y
  block:
    var (_,y) = (1,x)
    echo y
  block:
    var (y,_,) = (x,1,)
    echo y
{.hint: "END".}

foo(1)
