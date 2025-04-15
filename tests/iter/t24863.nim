# issue #24863

type M = object
  p: iterator(): M {.gcsafe.}

template h(f: M): int =
  yield f
  456

proc s(): M =
  iterator g(): M {.closure.} = discard
  let v = M(p: g)
  doAssert(not isNil(v.p))
  discard v.p()
  v

proc c(): M =
  iterator b(): M {.closure.} =
    let r = h(s())
    doAssert r == 456
    proc n(): M =
      iterator y(): M {.closure.} =
        let _ = r
      let _ = y
    let _ = proc () = discard n()
  let j = M(p: b)
  doAssert(not isNil(j.p))
  discard j.p()

let _ = c()
