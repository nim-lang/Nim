discard """
  output: '''
true
true
true
true
true
true
true
true
5
5
false
'''
"""

# bug #26468
import std/macros

template tp() {.pragma.}
template val(x: int) {.pragma.}

type
  Gen[T] {.tp.} = object
  Alias = Gen[int]
  Obj {.tp.} = object
  ObjAlias = Obj
  Ref {.tp.} = ref object
  RefAlias = Ref
  AliasAlias = RefAlias
  ValObj {.val: 5.} = object
  ValAlias = ValObj
  Plain = object
  PlainAlias = Plain

echo Gen[int].hasCustomPragma(tp)
echo Alias.hasCustomPragma(tp)
echo ObjAlias.hasCustomPragma(tp)
echo RefAlias.hasCustomPragma(tp)
echo AliasAlias.hasCustomPragma(tp)

var a: Alias
var r: RefAlias
var o: ObjAlias
echo a.hasCustomPragma(tp)
echo r.hasCustomPragma(tp)
echo o.hasCustomPragma(tp)
echo ValAlias.getCustomPragmaVal(val)
var v: ValAlias
echo v.getCustomPragmaVal(val)
echo PlainAlias.hasCustomPragma(tp)
