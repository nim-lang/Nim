discard """
  outputsub: '''
t10137.nim(29, 5)        t10137
t10137.nim(27, 36)       main
t10137.nim(23, 11)       foo1
'''
exitcode: "1"
"""











## line 20

proc foo1(a: int): auto =
  doAssert a < 4
  result = a * 2

proc main()=
  if foo1(1) > 0: discard foo1(foo1(2))

main()
