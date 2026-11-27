discard """
  action: reject
  nimout: '''
  the conversion does not keep the l-value of 'r'; copy it into a local variable, pass that and assign it back
'''
"""

# #26775: say how to pass a variable when a conversion is rejected for `var`

type R = range[0..3]

proc inc2(x: var int) = x += 1

var r: R = 1

inc2(int(r)) #[tt.Error
    ^ type mismatch: got <int>]#
