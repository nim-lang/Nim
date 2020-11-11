discard """
outputsub: '''tcall_with_default_arg.nim(16) anotherFoo'''
exitcode: 1
"""
# issue: #5604

proc fail() =
  raise newException(ValueError, "dead")

proc getDefault(): int = 123

proc bar*(arg1: int = getDefault()) =
  fail()

proc anotherFoo(input: string) =
  bar()

anotherFoo("123")
