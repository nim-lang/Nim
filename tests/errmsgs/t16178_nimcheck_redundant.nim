discard """
cmd: '''nim check --hints:off $file'''
action: reject
nimoutFull: true
nimout: '''
t16178_nimcheck_redundant.nim(22, 11) Error: undeclared identifier: 'bad5'
t16178_nimcheck_redundant.nim(22, 15) Error: expression '' has no type (or is ambiguous)
t16178_nimcheck_redundant.nim(22, 7) Error: 'let' symbol requires an initialization
t16178_nimcheck_redundant.nim(26, 11) Error: expression '' has no type (or is ambiguous)
t16178_nimcheck_redundant.nim(26, 7) Error: 'let' symbol requires an initialization
t16178_nimcheck_redundant.nim(30, 11) Error: expression '' has no type (or is ambiguous)
t16178_nimcheck_redundant.nim(34, 15) Error: expression '' has no type (or is ambiguous)
'''
"""
#[
xxx the line `Error: 'let' symbol requires an initialization` is redundant and should not
be reported; likewise with `t16178_nimcheck_redundant.nim(22, 15) Error: expression '' has no type (or is ambiguous)`
]#

# line 20
block:
  let a = bad5(1)

block: # bug #12741
  macro foo = discard
  let x = foo

block:
  macro foo2 = discard
  discard foo2

block:
  macro foo3() = discard
  discard foo3()
