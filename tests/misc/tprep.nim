discard """
nimout: '''
tprep.nim(25, 9) Hint: Case 2 [User]
tprep.nim(27, 11) Hint: Case 2.3 [User]
'''
outputsub: ""
"""

# Test the features that used to belong to the preprocessor

import
  times

#{.warning: "This is only a test warning!".}

const
  case2 = true
  case3 = true

when defined(case1):
  {.hint: "Case 1".}
  when case3:
    {.hint: "Case 1.3".}
elif case2:
  {.hint: "Case 2".}
  when case3:
    {.hint: "Case 2.3".}
elif case3:
  {.hint: "Case 3".}
else:
  {.hint: "unknown case".}

var
  s: string
write(stdout, "compiled at " & system.CompileDate &
              " " & CompileTime & "\n")
echo getDateStr()
echo getClockStr()
