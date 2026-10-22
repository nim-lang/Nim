discard """
joinable: false
cmd: "nim check --parsem:on --sinkInference:on $file"
action: compile
"""

# `--parsem:on` variant of tests/destructor/tinvalid_rebind: the body of `main` no
# longer lifts `=destroy` before the explicit one is declared, so the explicit
# one binds.

type
  Foo[T] = object

proc main =
  var f: Foo[int]

proc `=destroy`[T](f: var Foo[T]) =
  discard
