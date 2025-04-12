# issue #13843

type
  IdLayer {.pure, size: int.sizeof.} = enum
    Core
    Ui
  IdScene {.pure, size: int.sizeof.} = enum
    Game
    Shop 
  SomeIds = IdLayer|IdScene
 
converter toint*(x: SomeIds): int = x.int

var IdGame : int = IdScene.Game #works

proc bind_scene(a, b: int) = discard
bind_scene(Core,Game)         # doesn't work, type mismatch for Game, doesnt convert to int
bind_scene(Core,IdScene.Game) # doesn't work, type mismatch for Game, doesnt convert to int
bind_scene(Core,IdGame)       # works 
