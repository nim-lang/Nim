discard
  """
  description: '''IC: a file read by `staticRead` is an input of the reading module's sem rule'''
"""

#? metamorphic

#!FILE dep.txt
alpha
#!FILE v.txt
one
#!FILE reader.nim
const d = staticRead("dep.txt")
proc readDep*(): string = d

#!FILE main.nim
import reader
const v = staticRead("v.txt")
echo v, readDep()
#!STEP expect: one\nalpha

# An edit to the file the main module reads re-fires its `nim m`.
#!FILE v.txt
two
#!STEP expect: two\nalpha

# An edit to the file an imported module reads re-fires that module's `nim m`
# and propagates through the backend to the binary.
#!FILE dep.txt
beta
#!STEP expect: two\nbeta
