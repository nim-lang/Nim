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
write(stdout, "compiled at " & system.compileDate &
              " " & compileTime & "\n")
echo getDateStr()
echo getClockStr()
