# test assert and exception handling

proc callB() = assert(False)
proc callA() = callB()
proc callC() = callA()

try:
  callC()
except EAssertionFailed:
  write(stdout, "assertion failure!\n")
except:
  write(stdout, "unknown exception!\n")
finally:
  system.write(stdout, "this shall be always written\n")

assert(false)
