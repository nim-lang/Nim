discard """
   errormsg: "type mismatch"
   output: '''
t25262.nim(13, 5) Error: type mismatch: got <>
but expected one of:
proc v[T: typedesc]()

expression: v[0]()
'''
"""

proc v[T: typedesc]() = discard
v[0]()