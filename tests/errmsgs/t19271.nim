discard """
  cmd: "nim check --hints:off $file"
  errormsg: ""
  nimout: '''
t19271.nim(21, 18) Error: 'MyFunc1' itself cannot be used as type of parameter 'f'
t19271.nim(24, 17) Error: 'MyFunc' itself cannot be used as type of parameter 'f'
'''
"""











type
  MyFunc1 = proc(f: MyFunc1)

type
  MyFunc = proc(f: ref MyFunc)