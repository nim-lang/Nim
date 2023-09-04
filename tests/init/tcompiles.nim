discard """
  matrix: "--warningAsError:ProveInit --warningAsError:Uninit"
"""

{.experimental: "strictdefs".}

type Test = object
  id: int

proc foo {.noreturn.} = discard

block:
  proc test(x: bool): Test =
    if x:
      foo()
    else:
      foo()

block:
  proc test(x: bool): Test =
    if x:
      result = Test()
    else:
      foo()

  discard test(true)

block:
  proc test(x: bool): Test =
    if x:
      result = Test()
    else:
      return Test()

  discard test(true)

block:
  proc test(x: bool): Test =
    if x:
      return Test()
    else:
      return Test()

  discard test(true)

block:
  proc test(x: bool): Test =
    if x:
      result = Test()
    else:
      result = Test()
      return

  discard test(true)

block:
  proc test(x: bool): Test =
    if x:
      result = Test()
      return
    else:
      raise newException(ValueError, "unreachable")

  discard test(true)
