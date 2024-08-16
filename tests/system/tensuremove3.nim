discard """
  errormsg: "cannot move 'x', passing 'x' to a sink parameter introduces an implicit copy"
  matrix: "--cursorinference:on; --cursorinference:off"
"""

block:
  type
    X = object
      s: string

  proc `=copy`(x: var X, y: X) =
    x.s = "copied " & y.s

  proc `=sink`(x: var X, y: X) =
    `=destroy`(x)
    wasMoved(x)
    x.s = "moved " & y.s

  proc consume(x: sink X) =
    discard x.s

  proc main =
    var s = "abcdefg"
    var x = X(s: ensureMove s)
    consume(ensureMove x)
    discard x

  main()