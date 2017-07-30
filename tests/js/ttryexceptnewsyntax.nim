discard """
  output: '''hello'''
"""

type
  MyException = ref Exception

#bug #5986

try:
  raise MyException(msg: "hello")
except MyException as e:
  echo e.msg
