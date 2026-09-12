discard """
  description: '''IC: `compiles((; import X))` resolves the same as under `nim c`'''
"""

#? metamorphic

# `tryImport` (a verbatim copy of stew/importops, the shape that broke
# nim-ssz-serialization's digest.nim) hides the optional `import` inside a
# template. Two things follow, and `nim ic` got both wrong:
#
#   * a syntactic dependency scan of a USER of `tryImport` sees only a
#     `tryImport foo` call, never an `import foo`, so `foo` is not scheduled and
#     the discovery fixpoint has to recover it from the post-sem `.s.deps`;
#   * the template's own body names `import v` -- `v` is its untyped parameter,
#     never a module -- inside the `when` CONDITION, and nifler's deps file
#     flattens an import written in a condition into an unguarded entry. The
#     scanner read that as a real top-level import and killed the whole build
#     with `mtryimportlib.nim: cannot open file: v` before compiling a line.
#
# The optional module must end up imported, exactly as `nim c` has it (the
# oracle every step is checked against).

#!FILE importops.nim
template tryImport*(v: untyped): bool =
  when compiles((; import v)):
    import v
    true
  else:
    false

#!FILE optdep.nim
proc optValue*(): string = "optional-present"

#!FILE chooser.nim
import importops

when tryImport optdep:
  proc chosen*(): string = optValue()
else:
  proc chosen*(): string = "optional-MISSING"

#!FILE main.nim
import chooser
echo chosen()
#!STEP expect: optional-present

# The module only the `compiles` probe pulled in is a graph node like any other:
# a warm build must see an edit to it.
#!FILE optdep.nim
proc optValue*(): string = "optional-edited"
#!STEP expect: optional-edited
