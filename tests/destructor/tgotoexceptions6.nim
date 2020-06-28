discard """
  cmd: "nim c --gc:arc --exceptions:goto $file"
  outputsub: "Error: unhandled exception: virus detected [ValueError]"
  exitcode: "1"
"""

# bug #13436
proc foo =
  raise newException(ValueError, "virus detected")
foo()
