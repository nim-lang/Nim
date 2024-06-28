discard """
  matrix: "--gc:refc; --gc:arc"
"""

# bug #23748

type
  O = ref object
    s: string
    cb: seq[proc()]

proc push1(o: O, i: int) =
  let o = o
  echo o.s, " ", i
  o.cb.add(proc() = echo o.s, " ", i)

proc push2(o: O, i: int) =
  let o = o
  echo o.s, " ", i
  proc p() = echo o.s, " ", i
  o.cb.add(p)

let o = O(s: "hello", cb: @[])
o.push1(42)  # This segfaults
o.push2(42)  # This also segfaults
