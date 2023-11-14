discard """
  action: compile
"""

block:
  func inCheck() =
    discard

  iterator iter(): int =
    yield 0
    yield 0

  func search() =
    let inCheck = 0

    for i in iter():

      proc hello() =
        inCheck()

  search()
block:
  iterator iter(): int =
    yield 0
    yield 0

  func search() =
    let lmrMoveCounter = 0

    for i in iter():

      proc hello() =
        discard lmrMoveCounter

  search()
