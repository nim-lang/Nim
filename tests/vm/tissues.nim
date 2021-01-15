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
