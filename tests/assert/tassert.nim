discard """
  outputsub: "assertion failure!this shall be always written"
  exitcode: "1"
"""
# test assert and exception handling

proc callB() = assert(false)
proc callA() = callB()
proc callC() = callA()

try:
  callC()
except AssertionDefect:
  write(stdout, "assertion failure!")
except:
  write(stdout, "unknown exception!")
finally:
  system.write(stdout, "this shall be always written")

assert(false) #OUT assertion failure!this shall be always written
