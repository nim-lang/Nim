discard """
  matrix: "--mm:orc; --mm:arc; --mm:refc"
"""

# bug #25595: cursor inference must not borrow a case object whose source can be
# mutated through the cursor's own ref across a call. `let c = h.w` was inferred as a
# non-owning cursor; `clear(c.r)` overwrites `h.w` via the cursor's back-reference,
# freeing the ref while the borrow still uses it -> use-after-free. Detected here
# deterministically: the element's destructor must not run during the call.

var destroyed = false

type
  O = ref object
    value: int
    home: H
  W = object
    case k: bool
    of true: r: O
    of false: discard
  H = ref object
    w: W

proc `=destroy`(o: var typeof(O()[])) =
  destroyed = true

proc clear(o: O): int =
  o.home.w = W()
  doAssert not destroyed, "use-after-free: element destroyed during the call"
  result = o.value

proc go(h: H): int =
  let c = h.w
  result = clear(c.r)

proc main =
  let h = H()
  let o = O(value: 42)
  o.home = h
  h.w = W(k: true, r: o)
  doAssert go(h) == 42

main()
