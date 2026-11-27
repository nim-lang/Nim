discard """
  description: '''IC: `config.nims` is re-evaluated when a `-d:` it reads changes (#26628)'''
"""

#? metamorphic

#!FILE config.nims
const mode {.strdefine.} = "NONE"
switch("define", "MODE_" & mode)
#!FILE main.nim
when defined(MODE_A):
  echo "MODE A"
when defined(MODE_B):
  echo "MODE B"
#!FLAGS -d:mode=A
#!STEP expect: MODE A

#!FLAGS -d:mode=B
#!STEP expect: MODE B

#!FLAGS -d:mode=A
#!STEP expect: MODE A
