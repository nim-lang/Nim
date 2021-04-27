discard """
cmd: '''nim check --hints:off $file'''
action: reject
nimoutFull: true
nimout: '''
t16178_nimcheck_redundant.nim(22, 11) Error: undeclared identifier: 'bad5'
t16178_nimcheck_redundant.nim(22, 7) Error: 'let' symbol requires an initialization
t16178_nimcheck_redundant.nim(26, 7) Error: 'let' symbol requires an initialization
'''
"""




#[
xxx the line `Error: 'let' symbol requires an initialization` is redundant and should not
be reported
]#

# line 20
block:
  let a = bad5(1)

block: # bug #12741
  macro foo = discard
  let x = foo
