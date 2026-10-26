discard """
  description: '''metamorphic IC with --parsem:on: bodies that call routines declared further down'''
"""

# A *metamorphic* IC test (see tmeta_smoke.nim). Every module relies on
# `--parsem:on`: routine bodies call routines, and instantiate generics,
# declared further down without forward declarations. The incremental
# invariants must hold for that code exactly as for ordinary code.

#? metamorphic

#!FLAGS --parsem:on

#!FILE a.nim
proc value*(): int = secret() + twice(1)
proc twice[T](x: T): T = later(x) * 2
proc later[T](x: T): T = x
proc secret(): int = 41

#!FILE main.nim
import a
proc run() = echo show(value())
proc show(x: int): string = "v=" & $x
run()

#!STEP expect: v=43

# --- body-only edit of a routine declared below its caller: no interface
#     cookie changes and only `a`'s codegen is redone.
#!FILE a.nim
proc value*(): int = secret() + twice(1)
proc twice[T](x: T): T = later(x) * 2
proc later[T](x: T): T = x
proc secret(): int = 999

#!STEP expect: v=1001; body-edit; modules: 1

# --- no-op edit.
#!FILE a.nim
proc value*(): int = secret() + twice(1)
proc twice[T](x: T): T = later(x) * 2
proc later[T](x: T): T = x
proc secret(): int = 999

#!STEP expect: v=1001; noop

# --- interface edit: `value`'s return type changes. The importer, whose body
#     calls `show` declared below it, must be re-sem'd. The final step also
#     runs the clean==incremental check.
#!FILE a.nim
proc value*(): int64 = (secret() + twice(1)).int64
proc twice[T](x: T): T = later(x) * 2
proc later[T](x: T): T = x
proc secret(): int = 999

#!FILE main.nim
import a
proc run() = echo show(value())
proc show(x: int64): string = "v=" & $x
run()

#!STEP expect: v=1001; iface-edit
