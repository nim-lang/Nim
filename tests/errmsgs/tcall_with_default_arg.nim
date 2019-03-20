discard """
outputsub: '''tcall_with_default_arg.nim(16) anderesfoo'''
exitcode: 1
"""
# issue: #5604

proc eineproc() =
  raise newException(ValueError, "irgendwie tot")

proc getDefault(): int = 123

proc bar*(arg1: int = getDefault()) =
  eineproc()

proc anderesfoo(input: string) =
  bar()

anderesfoo("123")
