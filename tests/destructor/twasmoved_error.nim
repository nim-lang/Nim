discard """
  cmd: '''nim c --mm:arc --errorMax:0 $file'''
  errormsg: "'=wasMoved' is not available for type <Holder>; routine: main2"
  nimout: '''
twasmoved_error.nim(38, 12) Error: '=wasMoved' is not available for type <Game>; routine: main
twasmoved_error.nim(47, 12) Error: '=wasMoved' is not available for type <Holder>; routine: main2
'''
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

# an object that contains such a type cannot be moved either
type Holder = object
  g: Game

proc main2 =
  var h: Holder
  var h2 = h
  echo "hello"

main()
main2()
