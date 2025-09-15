discard """
  matrix: "--warningAsError:Deprecated"
"""

block: # bug #24905
  proc y() {.deprecated.} = discard
  proc v(_: int | int) =
    {.push warning[Deprecated]: off.}
    y()
    {.pop.}

  v(1)

block: # bug #24903
  block:
    proc y() {.deprecated.} = discard
    proc m(_: int | int) =
      when false: y()

  block:
    proc y() {.error.} = discard
    proc m(_: int | int) =
      when false: y()

  block:
    proc y() {.error.} = discard
    proc m(_: int | int) =
      when true: y()

block: # bug #15650
  proc bar() {.deprecated.} = discard

  template foo() =
    when false:
      bar()
    else:
      discard

  foo()
