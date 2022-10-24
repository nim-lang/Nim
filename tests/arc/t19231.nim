discard """
  matrix: "--mm:orc"
  targets: "c cpp"
"""

type
  Game* = ref object

proc free*(game: Game) =
  var mixNumOpened:cint = 0
  for i in 0..<mixNumOpened:
    mixNumOpened -= 1

proc newGame*(): Game =
  new result, free

var
  game*: Game
