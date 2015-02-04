
type
  TMyObj = TYourObj
  TYourObj = object of RootObj
    x, y: int

proc init: TYourObj =
  result.x = 0
  result.y = -1

proc f(x: var TYourObj) =
  discard

var m: TMyObj = init()
f(m)
