discard """
cmd: "nim check $file"
errormsg: "invalid type: 'typedesc[int]' in this context: 'array[0..0, typedesc[int]]' for var"
nimout: '''
t9932.nim(10, 5) Error: invalid type: 'type' in this context: 'array[0..0, type]' for var
t9932.nim(11, 5) Error: invalid type: 'typedesc[int]' in this context: 'array[0..0, typedesc[int]]' for var
'''
"""

var y: array[1,type]
var x = [int]
