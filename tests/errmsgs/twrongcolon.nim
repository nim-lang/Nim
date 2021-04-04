discard """
errormsg: "in expression ' do:"
nimout: '''
twrongcolon.nim(11, 12) Error: in expression ' do:
  890': identifier expected, but found ''
'''

line: 11
"""

var n: int : 890
