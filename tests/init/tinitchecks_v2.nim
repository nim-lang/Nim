discard """
cmd: "nim check $file"
action: "compile"
"""

{.experimental: "strictDefs".}

proc myopen(f: out File; s: string): bool =
  f = default(File)
  result = false

proc main =
  var f: File
  if myopen(f, "aarg"):
    f.close

proc invalid =
  var s: seq[string]
  s.add "abc" #[tt.Warning
  ^ use explicit initialization of 's' for clarity [Uninit] ]#

proc valid =
  var s: seq[string] = @[]
  s.add "abc" # valid!

main()
invalid()
valid()

proc branchy(cond: bool) =
  var s: seq[string]
  if cond:
    s = @["y"]
  else:
    s = @[]
  s.add "abc" # valid!

branchy true

proc p(x: out int; y: out string; cond: bool) = #[tt.Warning
                   ^ Cannot prove that 'y' is initialized. This will become a compile time error in the future. [ProveInit] ]#
  x = 4
  if cond:
    y = "abc"
  # error: not every path initializes 'y'

var gl: int
var gs: string
p gl, gs, false

proc canRaise(x: int): int =
  result = x
  raise newException(ValueError, "wrong")

proc currentlyValid(x: out int; y: out string; cond: bool) =
  x = canRaise(45)
  y = "abc" # <-- error: not every path initializes 'y'

currentlyValid gl, gs, false
