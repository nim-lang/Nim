discard """
  file: "tnestedreturn.nim"
  output: "A\nB\nC\n"
"""

# Various tests of return nested in double try/except statements

proc test1() =

  finally: echo "A"

  try:
    raise newException(EOS, "Problem")
  except EOS:
    return

test1()


proc test2() =

  finally: echo "B"

  try:
    return
  except EOS:
    discard

test2()

proc test3() =
  try:
    try:
      raise newException(EOS, "Problem")
    except EOS:
      return
  finally:
    echo "C"

test3()
