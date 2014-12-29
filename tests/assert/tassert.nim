discard """
  file: "tassert.nim"
  outputsub: "assertion failure!this shall be always written"
  exitcode: "1"
"""
# test assert and exception handling

proc callB() = assert(false)
proc callA() = callB()
proc callC() = callA()

try:
  callC()
except EAssertionFailed:
  write(stdout, "assertion failure!")
except:
  write(stdout, "unknown exception!")
finally:
  system.write(stdout, "this shall be always written")

assert(false) #OUT assertion failure!this shall be always written


