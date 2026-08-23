discard """
  description: '''metamorphic IC: clean==incremental, no-op stability, body vs interface boundary'''
"""

# This is a *metamorphic* IC test (see the `#? metamorphic` marker and the
# runner in testament/categories.nim). It drives a sequence of cross-module
# edits through `nim ic` in one fixed build directory and checks the invariants
# the incremental backend must uphold (doc/ic_ideas.md).

#? metamorphic

#!FILE a.nim
proc greet*(): string = "hi"
proc secret(): int = 41          # private, body-only churn target
proc value*(): int = secret() + 1

#!FILE main.nim
import a
echo greet(), " ", value()

#!STEP expect: hi 42

# --- body-only edit: a private body changes, no signature does.
#     => no `*.iface.bif` cookie changes, exactly 1 module's codegen rebuilds,
#     the importer is left untouched.
#!FILE a.nim
proc greet*(): string = "hi"
proc secret(): int = 999
proc value*(): int = secret() + 1

#!STEP expect: hi 1000; body-edit; modules: 1

# --- no-op edit: re-emit byte-identical content. Nothing downstream may change.
#!FILE a.nim
proc greet*(): string = "hi"
proc secret(): int = 999
proc value*(): int = secret() + 1

#!STEP expect: hi 1000; noop

# --- interface edit: `value`'s return type changes (a signature change) while
#     main.nim's source stays byte-identical. The interface cookie must change
#     and the importer must be re-sem'd & recodegen'd (>= 2 modules rebuilt).
#     The final step also runs the clean==incremental check.
#!FILE a.nim
proc greet*(): string = "hi"
proc secret(): int = 999
proc value*(): int64 = secret().int64 + 1

#!STEP expect: hi 1000; iface-edit
