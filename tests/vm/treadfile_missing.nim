discard """
  errormsg: "unhandled exception: cannot open: does/not/exist.txt [IOError]"
  line: 9
"""

# bug #22558, bug #24530; a failing compile-time `readFile` crashed the
# compiler instead of reporting an error
static:
  discard readFile("does/not/exist.txt")
