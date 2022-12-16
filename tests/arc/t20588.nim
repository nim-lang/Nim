discard """
  cmd: "nim check --warnings:off --hints:off $file"
  errormsg: ""
  nimout: '''
t20588.nim(20, 12) Error: illegal type conversion to 'auto'
t20588.nim(21, 14) Error: illegal type conversion to 'typed'
t20588.nim(22, 16) Error: illegal type conversion to 'untyped'
'''
"""










discard 0.0.auto
discard typed("abc")
discard untyped(4)
