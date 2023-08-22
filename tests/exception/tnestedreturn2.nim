discard """
  outputsub: "Error: unhandled exception: Problem [OSError]"
  exitcode: "1"
"""

proc test4() =
  try:
    try:
      raise newException(OSError, "Problem")
    except OSError:
      return
  finally:
    discard

# Should cause unhandled exception error,
# but could cause segmentation fault if
# exceptions are not handled properly.
test4()
raise newException(OSError, "Problem")
