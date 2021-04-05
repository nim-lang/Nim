discard """
errormsg: "in expression ' do:"
nimout: '''
twrongcolon.nim(10, 12) Error: in expression ' do:
  890': identifier expected, but found ''
'''

"""

var n: int : 890
