discard """
  output: '''
Nim 3.4368930843, 0.3299290698
C double: 3.4368930843, 0.3299290698'''
"""

import math, strutils

{.emit: """
void printFloats(void) {
  double y = 1.234567890123456789;
  printf("C double: %.10f, %.10f\n", exp(y), cos(y));
}
""".}

proc c_printf(frmt: cstring) {.importc: "printf", header: "<stdio.h>", varargs.}
proc printFloats {.importc, nodecl.}

var x: float = 1.234567890123456789
c_printf("Nim %.10f, %.10f\n", exp(x), cos(x))
printFloats()
