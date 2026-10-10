discard """
  description: '''IC: a failed `nim m` must not poison the cache'''
"""

#? metamorphic

# A `nim m` that errored still wrote its `.s.bif` and cookie sidecars. nifmake
# then saw the rule satisfied (outputs newer than inputs) and the NEXT run
# reported success for a program that does not compile — linking a binary
# generated from error-bearing AST, or crashing codegen outright. Expressing
# this needs a step that is allowed to FAIL and a following step that recovers.

#!FILE dep.nim
proc value*(): int = 41

#!FILE main.nim
import dep
echo value() + 1
#!STEP expect: 42

# introduce a real error
#!FILE dep.nim
proc value*(): int = undefinedThing() + 1
#!STEP fails: undeclared identifier: 'undefinedThing'

# ... and again: the second run must NOT decide the rule is up to date.
#!STEP fails: undeclared identifier: 'undefinedThing'

# fixing it must rebuild rather than serve the poisoned artifact
#!FILE dep.nim
proc value*(): int = 100
#!STEP expect: 101
