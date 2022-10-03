discard """
  cmd: "nim check --hints:off $file"
  errormsg: ""
  nimout: '''
t12741.nim(22, 9) Error: expression 'foo' has no type (or is ambiguous)
t12741.nim(22, 5) Error: 'let' symbol requires an initialization
'''
"""











macro foo = discard

let x = foo