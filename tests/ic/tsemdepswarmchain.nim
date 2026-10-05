discard
  """
  description: '''IC: restore transitive semantic imports before pruning a warm build'''
"""

#? metamorphic

#!FLAGS --skipParentCfg --skipUserCfg --mm:arc

#!FILE leaf.nim
var message = "cached import"

proc answer*(): string =
  message

#!FILE guarded.nim
const Enabled = true
when Enabled:
  import leaf

proc reveal*(): string =
  when Enabled:
    answer()
  else:
    "guard disabled"

#!FILE generated.nim
import std/macros

macro importGuarded(): untyped =
  parseStmt("import guarded")

importGuarded()
proc value*(): string =
  reveal()

#!FILE main.nim
import generated
echo value()
#!STEP expect: cached import

# Neither the generated import nor its guarded dependency may disappear when
# every source and semantic artifact is already cached.
#!STEP expect: cached import

#!FILE leaf.nim
var message = "edited import"

proc answer*(): string =
  message

#!STEP expect: edited import; body-edit; modules: 1

#!STEP expect: edited import; noop

# A stale sidecar must not keep the guarded import alive after its branch is
# disabled, even when its importer was discovered from another sidecar.
#!FILE guarded.nim
const Enabled = false
when Enabled:
  import leaf

proc reveal*(): string =
  when Enabled:
    answer()
  else:
    "guard disabled"

#!FILE leaf.nim
{.error: "inactive dependency was compiled".}
#!STEP expect: guard disabled

#!STEP expect: guard disabled; noop
