discard """
  action: compile
"""

{.push warningAsError[Effect]: on.}

{.experimental: "strictEffects".}

proc fn(a: int, p1, p2: proc()) {.effectsOf: p1.} =
  if a == 7:
    p1()
  if a<0:
    raise newException(ValueError, $a)

proc main() {.raises: [ValueError].} =
  fn(1, proc()=discard, proc() = raise newException(IOError, "foo"))
main()

# bug #19159

import macros

func mkEnter() =
  template helper =
    discard
  when defined pass:
    helper()
  else:
    let ast = getAst(helper())


# bug #6559
type
  SafeFn = proc (): void {. raises: [] }

proc ok() {. raises: [] .} = discard
proc fail() {. raises: [] .}

let f1 : SafeFn = ok
let f2 : SafeFn = fail


proc fail() = discard
f1()
f2()

