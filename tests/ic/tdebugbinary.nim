discard
  """
  description: '''IC: native debug binaries are reproducible after body edits'''
"""

#? metamorphic

#!FLAGS --skipParentCfg --skipUserCfg --debugger:native

#!FILE value.nim
proc value*(): string =
  "initial"

#!FILE main.nim
import value
echo value()
#!STEP expect: initial

#!FILE value.nim
proc value*(): string =
  "edited"

#!STEP expect: edited; body-edit; modules: 1

#!FILE value.nim
proc value*(): string =
  "initial"

#!STEP expect: initial; body-edit; modules: 1

#!STEP expect: initial; noop
