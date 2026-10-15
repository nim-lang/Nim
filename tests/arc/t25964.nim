discard """
  matrix: "--mm:orc; --mm:arc"
  output: '''
done
'''
"""

# bug #25964: cursor inference made `snapshot` a cursor aliasing `hs` instead of
# copying it. The stored closures mutate a captured global whose value was moved
# into `hs`, so the aliased seq was cleared while still in use -> segfault. The
# mutation is invisible to the analysis (it happens in a different proc, through
# the closure environment), so the copy must not be elided.

type C = proc() {.closure.}

proc clear(h: var seq[C]) =
  for i in countdown(h.len-1, 0): h[i] = nil

proc emit(hs: seq[C]) =
  var snapshot = hs
  for r in snapshot:
    r()

var handlers: seq[C]
handlers = @[
  C(proc() {.closure.} = clear(handlers)),
  C(proc() {.closure.} = discard)]
emit(handlers)
echo "done"
