import std/references

block:
  var x = @[1,2,3]
  let x0=x[1]
  byaddr x1=x[1]
  x1+=10
  doAssert type(x1) is int and x == @[1,12,3]

  byaddr
    x2=x[1]
  doAssert x2.addr == x1.addr

  when false:
    # this could be supported but would require a macro instead of a simple
    # template in `byAddrImpl`
    byaddr
      x2=x[1]
      x3=x[1]
    doAssert x2.addr == x3.addr

import std/macros

macro dbg(a): string = newLit a.treeRepr
let s = dbg:
  byaddr foo = bar
doAssert s == """
StmtList
  CustomDefSection
    Ident "byaddr"
    IdentDefs
      Ident "foo"
      Empty
      Ident "bar""""
