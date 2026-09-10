discard """
  description: '''IC: changing the compiler switches must invalidate the cache'''
"""

#? metamorphic

# nifmake decides staleness from file mtimes and never looks at a rule's command
# line, so `-d:` / `--mm:` / `--opt:` changes re-generated the build file with
# the new switches and re-fired nothing: a silently stale binary built with the
# PREVIOUS configuration. And switches given only on the driver's command line
# never reached the per-module children at all, because they replay the
# project's config files rather than the driver's argv.

#!FILE cfg.nim
const Mode* {.strdefine.} = "plain"

proc describe*(): string =
  when Mode == "loud": "LOUD"
  elif Mode == "quiet": "quiet"
  else: "plain"

#!FILE main.nim
import cfg
echo describe()
#!STEP expect: plain

#!FLAGS -d:Mode=loud
#!STEP expect: LOUD

#!FLAGS -d:Mode=quiet
#!STEP expect: quiet

#!FLAGS
#!STEP expect: plain
