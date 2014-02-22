discard """
  file: "tnestedreturn.nim"
  outputsub: "Error: unhandled exception: Problem [EOS]"
  exitcode: "1"
"""

proc test4() =
  try:
    try:
      raise newException(EOS, "Problem")
    except EOS:
      return
  finally:
    discard

# Should cause unhandled exception error,
# but could cause segmentation fault if 
# exceptions are not handled properly.
test4()
raise newException(EOS, "Problem")
