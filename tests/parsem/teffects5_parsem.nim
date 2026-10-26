discard """
  matrix: "--parsem:on"
  errormsg: "undeclared identifier: 'EIO'"
  line: 15
"""

# `--parsem:on` variant of tests/effects/teffects5: the body of `p` (where the
# type mismatch of the original is) is checked after the top-level statements,
# so the top-level error comes first.

proc p(q: proc() ): proc() {.tags: [], raises: [], closure.} =
  return proc () =
    q()

let yay = p(proc () = raise newException(EIO, "IO"))

proc main() {.raises: [], tags: [].} = yay()

main()
