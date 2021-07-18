import compiler/ast
import std/macros

from compiler/ast {.all.} as ast2 import toHumanStrImpl

proc sanityCheck() =
  #[
  ensures `macros` definitions are kept in sync with ast.nim. Note that we
  could allow removing enum members in macros.nim as follows:
  * https://github.com/nim-lang/RFCs/issues/190 (`when in enum`, least hacky)
  * using `string` comparisons instead of `ord` in macros APIs, e.g. `genSym`.
  ]#
  template fn(T1, T2) =
    var s1: seq[string]
    var s2: seq[string]
    # adjust as needed during bootstrap if `TSymKind` is modified.
    for a in T1: s1.add toHumanStrImpl(a, 2)
    for a in T2: s2.add toHumanStrImpl(a, 3)
    if s1 != s2:
      for i in 0..<min(s1.len, s2.len):
        when T1 is TSymKind:
          discard
        when T1 is TTypeKind:
          # xxx eventually these special cases should be fixed
          # xxx change builtInTypeClass => builtinTypeClass
          if s1[i] == "owned" and s2[i] == "unused0": continue
          elif s1[i] == "sink" and s2[i] == "unused1": continue
          elif s1[i] == "lent" and s2[i] == "unused2": continue
          elif s1[i] == "proxy" and s2[i] == "error": continue
          elif s1[i] == "builtInTypeClass" and s2[i] == "builtinTypeClass": continue
        elif T1 is TNodeKind:
          discard
          if s1[i] == "owned" and s2[i] == "unused0": continue
          if s1[i] == "sink" and s2[i] == "unused1": continue
          if s1[i] == "lent" and s2[i] == "unused2": continue
          if s1[i] == "proxy" and s2[i] == "error": continue
          if s1[i] == "builtInTypeClass" and s2[i] == "builtinTypeClass": continue
        doAssert s1[i] == s2[i], $(i, s1[i], s2[i], $T1)
      when T1 is TNodeKind:
        doAssert lastKindExposedInMacros.ord + 1 == s2.len, $(lastKindExposedInMacros.ord, s2.len)
      else:
        doAssert s1.len == s2.len, $(s1.len, s2.len)
  fn(TSymKind, NimSymKind)
  fn(TTypeKind, NimTypeKind)
  fn(TNodeKind, NimNodeKind)
sanityCheck()
