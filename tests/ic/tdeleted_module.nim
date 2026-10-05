discard """
  description: '''IC: deleting a still-imported module must be an error'''
"""

#? metamorphic

# Deleting a file moves no mtime, so nothing in an mtime-keyed build re-fires:
# `nim ic` relinked a stale binary while `nim c` reported `cannot open file`.
# The dependency scan is the only part of the pipeline that looks at import
# paths at all, so that is where the vanished module has to be noticed.

#!FILE helper.nim
proc help*(): string = "helped"

#!FILE main.nim
import helper
echo help()
#!STEP expect: helped

#!DELETE helper.nim
#!STEP fails: cannot open file

# putting it back recovers
#!FILE helper.nim
proc help*(): string = "back"
#!STEP expect: back
