## This module implements syntax sugar for some declarations.

import std/macros

macro byaddr*(sect) =
  ## Allows a syntax for l-value references, being an exact analog to
  ## `auto& a = ex;` in C++.
  ## 
  ## .. warning:: This makes use of 2 experimental features, namely nullary
  ##   templates instantiated as symbols and variable macro pragmas.
  ##   For this reason, its behavior is not stable. The current implementation
  ##   allows redefinition, but this is not an intended consequence.
  runnableExamples:
    var s = @[10, 11, 12]
    var a {.byaddr.} = s[0]
    a += 100
    assert s == @[110, 11, 12]
    assert a is int
    var b {.byaddr.}: int = s[0]
    assert a.addr == b.addr
  expectLen sect, 1
  let def = sect[0]
  let
    lhs = def[0]
    typ = def[1]
    ex = def[2]
    addrTyp = if typ.kind == nnkEmpty: typ else: newTree(nnkPtrTy, typ)
  result = quote do:
    let tmp: `addrTyp` = addr(`ex`)
    template `lhs`: untyped = tmp[]
  result.copyLineInfo(def)
