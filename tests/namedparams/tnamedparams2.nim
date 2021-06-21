import pegs

discard parsePeg(
      pattern = "input",
      filename = "filename",
      line = 1,
      col = 23)

# bug #12196
type
  Renderer = object

var xs0, x0, xs1, x1: int
proc init(xs=xs0; x=x0; renderer: Renderer; r: byte) = discard
init(xs=xs1, x=x1, r=3, renderer=Renderer())
