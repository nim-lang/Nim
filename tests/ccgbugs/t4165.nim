discard """
  targets: "c cpp"
  output: '''
42
hello static
'''
"""

# bug #4165: `static` parameters used in `emit`
{.emit: """/*INCLUDESECTION*/
#include <stdio.h>
""".}

proc printInt(x: static[int]) =
  {.emit: "printf(\"%d\\n\", (int)`x`); fflush(stdout);".}

printInt(42)

proc printStr(s: static[string]) =
  {.emit: "printf(\"%s\\n\", `s`.p->data); fflush(stdout);".}

printStr("hello static")
