discard """
cmd: "nim check --hints:off $file"
action: reject
nimout: '''
t26260.nim(11, 20) Error: undeclared identifier: 'f'
t26260.nim(11, 20) Error: undeclared identifier: 'f'
t26260.nim(11, 20) Error: invalid pragma: f
'''
"""

type T[P] = proc {.f.}
