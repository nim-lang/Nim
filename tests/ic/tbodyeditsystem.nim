discard """
  description: '''IC: a body-only edit rebuilds no interface, including system's'''
"""

#? metamorphic

# `system` compiles its conditional imports in its own process whatever the
# dependency scanner decided; a warm run must not see a different graph for it
# (and re-sem it) after an unrelated body-only edit.

#!FILE dep.nim
proc bump*[T](x: T): T = x + 1

#!FILE main.nim
import dep
echo bump(1)
#!STEP expect: 2

#!FILE dep.nim
proc bump*[T](x: T): T = x + 2
#!STEP expect: 3; body-edit
