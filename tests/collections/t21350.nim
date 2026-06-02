discard """
  matrix: "--mm:orc; --mm:arc; --mm:refc"
"""

# bug #21350: a seq of a {.requiresInit.} object variant must be usable.
# Two shapes, because they hit different paths:
#   * int-only variant (supportsCopyMem) -> only setLen-grow's default(T)
#   * variant with a string (not copyMem) -> also shrink's reset
# setLen-grow on a no-default element is covered by the UnsafeSetLen warning.
{.push warning[UnsafeSetLen]: off, warning[UnsafeDefault]: off.}

block: # int-only variant (the original #21350 shape); declaration alone used to fail
  type RI {.requiresInit.} = object
    case o: bool
    of true: discard
    else: foo: int
  var s: seq[RI]
  s.add RI(o: false, foo: 1)
  s.add RI(o: true)
  doAssert s.len == 2
  doAssert (not s[0].o) and s[0].foo == 1
  doAssert s[1].o

block: # non-copyMem element (string) also exercises shrink/reset
  type R {.requiresInit.} = object
    case o: bool
    of true:  v: int
    of false: e: string
  var s = newSeqOfCap[R](4)
  s.add R(o: true, v: 1)
  s.add R(o: false, e: "x")
  doAssert s.len == 2
  doAssert (not s[1].o) and s[1].e == "x"
  s.setLen(1)            # shrink: reset on the removed element
  doAssert s.len == 1
  doAssert s[0].o and s[0].v == 1

{.pop.}
