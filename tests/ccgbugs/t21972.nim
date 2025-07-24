discard """
    targets: "c cpp"
    outputsub: "Error: unhandled exception: Err2 [IOError]"
    exitcode: "1"
"""

proc bar(x: var int) =
  inc x
  if x == 3:
    raise newException(ValueError, "H0")

  elif x == 5:
    raise newException(IOError, "H1")

  elif x > 7:
    raise newException(IOError, "H2")


proc foo() =
  var i = 0
  while true:
    try:
      bar(i)
      echo i

    except ValueError:
      debugEcho("ValueError")

    except IOError:
      raise newException(IOError, "Err2")

when isMainModule:
  foo()