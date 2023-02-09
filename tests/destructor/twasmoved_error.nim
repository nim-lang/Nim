discard """
  cmd: '''nim c --mm:arc $file'''
  errormsg: "'=wasMoved' is not available for type <Game>; routine: main"
"""

# bug #19291

const
  screenWidth = 800
  screenHeight = 450

var
  ready = false
type
  Game = object

proc `=destroy`(x: var Game) =
  assert ready, "Window is already opened"
  ready = false

proc `=sink`(x: var Game; y: Game) {.error.}
proc `=copy`(x: var Game; y: Game) {.error.}
proc `=wasMoved`(x: var Game) {.error.}

proc initGame(width, height: int32, title: string): Game =
  assert not ready, "Window is already closed"
  ready = true

proc update(x: Game) = discard

proc main =
  var g = initGame(screenWidth, screenHeight, "Tetris raylib")
  g.update()
  var g2 = g
  echo "hello"

main()
