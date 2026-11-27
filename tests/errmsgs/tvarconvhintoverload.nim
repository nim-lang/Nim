discard """
  action: reject
  nimout: '''
  the conversion does not keep the l-value of 's'; copy it into a local variable, pass that and assign it back
'''
"""

# #26775: the same hint when several overloads of the routine are candidates

type R = range[0..3]

proc inc3(x: var int) = x += 1
proc inc3(x: var float) = x += 1.0

var s: R = 1

inc3(int(s)) #[tt.Error
    ^ type mismatch: got <int>]#
