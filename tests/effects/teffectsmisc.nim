discard """
  output: '''
printing from adder
'''
"""

import std/sugar

block:
  proc makeAdder(a: int): (int) -> void =
    proc discard_adder(x: int) {.closure.} =
      discard a + x

    proc echo_adder(x: int) {.closure.} =
      echo("printing from adder")

    if a > 0:
      discard_adder
    else:
      echo_adder

  let newAdder = makeAdder(0)
  newAdder(5)

block:
  proc makeAdder(a: int): (int) -> void =
    proc discard_adder(x: int) {.closure.} =
      discard a + x

    proc echo_adder(x: int) {.closure.} =
      echo("printing from adder")

    if a > 0:
      echo_adder
    else:
      discard_adder

  let newAdder = makeAdder(0)
  newAdder(5)

block:
  proc g() = discard
  proc f() {.raises: [IOError].} =
    try:
      g()
    except IOError:
      raise

  f()


block:
  proc g() = discard
  proc f() {.raises: [IOError].} =
    try:
      g()
    except IOError as e:
      raise

  f()