discard """
  action: reject
  matrix: "--mm:orc; --mm:refc"
  errormsg: "cannot move cursor 'a'; a cursor does not own its value"
"""

# bug #26010: a cursor is a non-owning alias and cannot transfer ownership.

type Xxx = object

proc `=destroy`(v: var Xxx) =
  debugEcho "dest"

proc test(v: ref Xxx) =
  var a {.cursor.} = v
  var b = move(a)
  discard

proc main() =
  var x = new Xxx
  test(x)

main()
