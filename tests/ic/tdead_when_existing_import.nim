discard """
  description: '''IC: do not compile an existing module reached only by an inactive conditional import'''
"""

#? metamorphic

#!FILE broken.nim
{.error: "inactive dependency was compiled".}

#!FILE valid.nim
proc chosen*(): string = "active"

#!FILE guarded.nim
const Backend* {.strdefine.} = "plain"
when Backend == "active":
  import ./valid
when Backend == "broken":
  import ./broken

proc pick*(): string =
  when Backend == "active": chosen()
  else: "plain"

#!FILE main.nim
import guarded
echo pick()
#!STEP expect: plain

#!FLAGS -d:Backend=active
#!STEP expect: active

#!FLAGS
#!STEP expect: plain
