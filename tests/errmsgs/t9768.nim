discard """
  errormsg: "unhandled exception:"
  file: "system/fatal.nim"
  nimout: '''
stack trace: (most recent call last)
t9768.nim(28, 33)        main
t9768.nim(23, 11)        foo1
'''
"""










## line 20

proc foo1(a: int): auto =
  doAssert a < 4
  result = a * 2

proc main()=
  static:
    if foo1(1) > 0: discard foo1(foo1(2))

main()
