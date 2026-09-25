discard """
  description: '''IC: an import dropped by a source edit is not compiled from the previous run's sem deps'''
"""

#? metamorphic

#!FILE valid.nim
proc chosen*(): string = "active"

#!FILE guarded.nim
const Backend = "active"
when Backend == "active":
  import ./valid

proc pick*(): string =
  when Backend == "active": chosen()
  else: "plain"

#!FILE main.nim
import guarded
echo pick()
#!STEP expect: active

#!FILE guarded.nim
const Backend = "plain"
when Backend == "active":
  import ./valid

proc pick*(): string =
  when Backend == "active": chosen()
  else: "plain"

#!FILE valid.nim
{.error: "no longer imported, but compiled".}
#!STEP expect: plain
