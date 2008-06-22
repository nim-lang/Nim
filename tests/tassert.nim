# test assert and exception handling

import
  io

proc callB() = assert(False)
proc callA() = callB()
proc callC() = callA()

try:
  callC()
except EAssertionFailed:
  io.write(stdout, "assertion failure!\n")
except:
  io.write(stdout, "unknown exception!\n")
finally:
  io.write(stdout, "this shall be always written\n")

assert(false)
