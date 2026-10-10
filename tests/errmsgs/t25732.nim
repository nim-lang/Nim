discard """
cmd: "nim check --hints:off $file"
action: "reject"
nimout: '''
t25732.nim(15, 32) Error: undeclared identifier: 'a'
t25732.nim(15, 32) Error: expression 'a' has no type (or is ambiguous)
t25732.nim(15, 33) Error: undeclared field: 'b'
t25732.nim(15, 33) Error: undeclared field: '.'
t25732.nim(15, 33) Error: undeclared field: '.'
'''
"""



static: (for f in [0]: discard a.b == f)