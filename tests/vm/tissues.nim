discard """
  nimout: "(Field0: 2, Field1: 2, Field2: 2, Field3: 2)"
"""

import macros

block t9043:
  proc foo[N: static[int]](dims: array[N, int])=
    const N1 = N
    const N2 = dims.len
    static: echo (N, dims.len, N1, N2)

  foo([1, 2])

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
    assert: t.n.kind == tree.kind
