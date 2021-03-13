import macros

block t9043: # issue #9043
  proc foo[N: static[int]](dims: array[N, int]): string =
    const N1 = N
    const N2 = dims.len
    const ret = $(N, dims.len, N1, N2)
    static: doAssert ret == $(N, dims.len, N1, N2)
    ret

  doAssert foo([1, 2]) == "(2, 2, 2, 2)"

block t4952:
  proc doCheck(tree: NimNode) =
    let res: tuple[n: NimNode] = (n: tree)
    assert: tree.kind == res.n.kind
    for sub in tree:
      doCheck(sub)

  macro id(body: untyped): untyped =
    doCheck(body)

  id(foo((i: int)))

  static:
    let tree = newTree(nnkExprColonExpr)
    let t = (n: tree)
    doAssert: t.n.kind == tree.kind


# bug #17199

proc merge(x: sink seq[string], y: sink string): seq[string] =
  newSeq(result, x.len + 1)
  for i in 0..x.len-1:
    result[i] = move(x[i])
  result[x.len] = move(y)

proc passSeq(data: seq[string]) =
  # used the system.& proc initially
  let wat = merge(data, "hello")

proc test =
  let name = @["hello", "world"]
  passSeq(name)
  doAssert name == @["hello", "world"]

static: test() # was buggy
test()
