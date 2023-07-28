discard """
  target: "c cpp js"
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
    var x = X(s: ensureMove "abcdefg")
    consume(ensureMove x)

  static: main()
  main()

block:
  type
    String = object
      id: string

  proc hello =
    var s = String(id: "1")
    var m = ensureMove s
    doAssert m.id == "1"

  hello()

when false:
  block:
    type
      String = object
        id: string

    proc hello =
      var n = "1"
      var s = String(id: ensureMove n)
      var m = ensureMove s
      doAssert m.id == "1"

    hello()