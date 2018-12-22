discard """
  targets: "c cpp"
  output: "A\nB\nC\n"
"""

# Various tests of return nested in double try/except statements

proc test1() =

  defer: echo "A"

  try:
    raise newException(OSError, "Problem")
  except OSError:
    return

test1()


proc test2() =

  defer: echo "B"

  try:
    return
  except OSError:
    discard

test2()

proc test3() =
  try:
    try:
      raise newException(OSError, "Problem")
    except OSError:
      return
  finally:
    echo "C"

test3()
