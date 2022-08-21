discard """
  errormsg: '''expression 'premultiply(app.gradient[i])' is of type 'Rgba8' and has to be used (or discarded)'''
  line: 22
"""

# bug #9076
type
  Rgba8 = object

proc premultiply*(c: var Rgba8): var Rgba8 =
  return c

type
  App = ref object
    gradient: seq[Rgba8]

method onDraw(app: App) {.base.} =
  var
    width  = 100'f64

  for i in 0..<width.int:
    app.gradient[i].premultiply()
