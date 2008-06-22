# Test the features that used to belong to the preprocessor

import
  io, times

{.warning: "This is only a test warning!".}

{.define: case2.}
{.define: case3.}
when defined(case1):
  {.hint: "Case 1".}
  when defined(case3):
    {.hint: "Case 1.3".}
elif defined(case2):
  {.hint: "Case 2".}
  when defined(case3):
    {.hint: "Case 2.3".}
elif defined(case3):
  {.hint: "Case 3".}
else:
  {.hint: "unknown case".}

var
  s: string
write(stdout, "compiled at " & system.compileDate &
              " " & compileTime & "\n")
echo getDateStr()
echo getClockStr()
