discard """
  matrix: "--mm:arc -d:useMalloc; --mm:arc"
"""

block: # bug #22058
  template foo(): auto =
    {.noSideEffect.}:
      newSeq[byte](1)

  type V = object
    v: seq[byte]

  proc bar(): V =
    V(v: foo())

  doAssert bar().v == @[byte(0)]

type
  GlobFilter* = object
    incl*: bool
    glob*: string

  GlobState* = object
    one: int
    two: int

proc aa() =
  let filters = @[GlobFilter(incl: true, glob: "**")]
  var wbg = newSeqOfCap[GlobState](1)
  wbg.add GlobState()
  var
    dirc = @[wbg]
  while true:
    wbg = dirc[^1]
    dirc.add wbg
    break

var handlerLocs = newSeq[string]()
handlerLocs.add "sammich"
aa()
aa()

block: # bug #24806
  block:
    proc aa() =
      var
        a = @[0]
        b = @[a]
      block:
        a = b[0]
        b.add a

    aa()

  block:
    proc aa() =
      var
        a = @[0]
        b = @[a]
      block:
        a = b[^1]
        b.add a

    aa()
