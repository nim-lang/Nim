discard """
  description: '''metamorphic IC: generic instantiation cache stability across edits'''
"""

# A generic lives in `gen` but is *instantiated* in `main` (the per-module
# backend emits instance bodies at the instantiation site). Editing the generic
# body must therefore rebuild both `gen` and `main`, and an incremental edit must
# still converge to exactly the same artifacts as a clean build. This exercises
# the static/generic-instance cache path that has historically been bug-prone.

#? metamorphic

#!FILE gen.nim
proc box*[T](x: T): seq[T] = @[x, x]

#!FILE main.nim
import gen
echo box(3).len, " ", box("hi")[0]

#!STEP expect: 2 hi

# --- edit the generic body: the importer holds the instantiations, so both the
#     definer and the instantiation site rebuild (2 modules).
#!FILE gen.nim
proc box*[T](x: T): seq[T] = @[x, x, x]

#!STEP expect: 3 hi; modules: 2

# --- re-emit identical content: nothing may change.
#!FILE gen.nim
proc box*[T](x: T): seq[T] = @[x, x, x]

#!STEP expect: 3 hi; noop
