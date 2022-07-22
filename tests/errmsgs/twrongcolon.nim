discard """
errormsg: "in expression '((890))'"
nimout: '''
twrongcolon.nim(8, 12) Error: in expression '((890))': identifier expected, but found ''
'''
"""

var n: int : 890
