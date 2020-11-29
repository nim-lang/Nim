discard """
  cmd: "nim c --gc:arc --exceptions:goto $file"
  outputsub: "Error: unhandled exception: Problem [OSError]"
  exitcode: "1"
"""

raise newException(OSError, "Problem")
