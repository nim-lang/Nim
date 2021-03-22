import std/macros

# xxx merge these into here: tmacros1.nim, tmacros_issues.nim, tmacros_various.nim, tmacrostmt.nim

block: # hasArgOfName
  macro m(u: untyped): untyped =
    for name in ["s","i","j","k","b","xs","ys"]:
      doAssert hasArgOfName(params u,name)
    doAssert not hasArgOfName(params u,"nonexistent")

  proc p(s: string; i,j,k: int; b: bool; xs,ys: seq[int] = @[]) {.m.} = discard

block: # bug #17454
  proc f(v: NimNode): string {.raises: [].} = $v

block: # asMacro
  proc test1(a: NimNode): NimNode = a
  proc test2(a: NimNode) = doAssert a.len == 3
  proc test3(a: NimNode): auto = a.repr
  proc test4(a, b: NimNode): auto = (a.repr, b.repr)
  proc test5(a: NimNode): auto = a.treeRepr
  proc test6(a: NimNode, b: int): auto = (a.repr, b)

  doAssert test3.asMacro("a" & "b") == """"a" & "b""""
  let a = test3.asMacro "a" & "b"
  doAssert a ==  """"a" & "b""""
  doAssert test3.asMacro(nonexistant) == "nonexistant"
  doAssert test4.asMacro("a" & "b", 12) == ("\"a\" & \"b\"", "12")

  doAssert test5.asMacro("a" & "b") == """
Infix
  Ident "&"
  StrLit "a"
  StrLit "b""""
  doAssert compiles(test2.asMacro("a" & "b"))
  doAssert not compiles(test2.asMacro("b"))
  doAssert test1.asMacro("a" & "b") == "ab"

  block: # shows lots of `macros` procs are made redundant by to `astGenRepr`
    doAssert repr.asMacro("a" & "b") == """"a" & "b""""
    doAssert treeRepr.asMacro("a" & "b") == """
Infix
  Ident "&"
  StrLit "a"
  StrLit "b""""

    doAssert astGenRepr.asMacro("a" & "b") == """
nnkInfix.newTree(
  newIdentNode("&"),
  newLit("a"),
  newLit("b")
)"""

  block: # static params
    doAssert test6.asMacro("a" & "b", static(32)) == ("\"a\" & \"b\"", 32)

  block:
    doAssert lispRepr.asMacro(1+2) == """(Infix (Ident "+") (IntLit 1) (IntLit 2))"""
    doAssert lispRepr.asMacro(1+2, static(true)) == """
(Infix
 (Ident "+")
 (IntLit 1)
 (IntLit 2))"""

  block:
    parseStmt.asMacro(static("proc fn(): int = 3*5"))
    parseStmt.asMacro(static("proc fn2(): int = 3*5")) # no redefinition error, thanks to `genSym(nskMacro, "impl")`
    assert fn() == 3*5
    assert fn2() == 3*5
