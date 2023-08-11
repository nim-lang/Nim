discard """
  cmd: "nim check --hints:off --warnings:off $file"
  action: "reject"
  nimout: '''
t21022.nim(17, 11) template/generic instantiation of `test` from here
t21022.nim(13, 3) Error: not all cases are covered
t21022.nim(23, 11) template/generic instantiation of `test` from here
t21022.nim(13, 3) Error: not all cases are covered
'''
"""

proc test(n: static[range[1..2]]): string = 
  case n
  of 1: result = "one"
  of 2: result = "two"

echo test 0

echo test 1

echo test 2

echo test 3
