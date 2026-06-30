discard """
  description: '''metamorphic IC: edit propagation across a 3-module import chain'''
"""

# Chain: main -> b -> a. Demonstrates that a body edit stays local to the edited
# module, while an interface edit propagates to its direct importer but stops
# where the next signature is unchanged. See doc/ic_ideas.md and the runner in
# testament/categories.nim.

#? metamorphic

#!FILE a.nim
proc base*(): int = 1

#!FILE b.nim
import a
proc mid*(): int = base() + 10

#!FILE main.nim
import b
echo mid()

#!STEP expect: 11

# --- body-only edit of `a.base`: no signature changes, so nothing re-sems;
#     only module `a`'s own codegen rebuilds.
#!FILE a.nim
proc base*(): int = 7

#!STEP expect: 17; body-edit; modules: 1

# --- interface edit of `a.base` (return type int -> int64). `b` uses `base`, so
#     `a`'s cookie change forces `b` to re-sem & recodegen; but `b.mid`'s own
#     signature is unchanged, so `main` is NOT rebuilt -> exactly 2 modules.
#     The final step also runs the clean==incremental check.
#!FILE a.nim
proc base*(): int64 = 7

#!STEP expect: 17; iface-edit; modules: 2
