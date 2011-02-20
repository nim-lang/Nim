discard """
  file: "tfloat3.nim"
  output: "Nimrod    3.4368930843, 0.3299290698 C double: 3.4368930843, 0.3299290698"
"""

import math, strutils

{.emit: """
void printFloats(void) {
    double y = 1.234567890123456789;
    
    printf("C double: %.10f, %.10f ", exp(y), cos(y));
}
""".}

proc c_printf(frmt: CString) {.importc: "printf", header: "<stdio.h>", varargs.}
proc printFloats {.importc, nodecl.}

var x: float = 1.234567890123456789
c_printf("Nimrod    %.10f, %.10f ", exp(x), cos(x))
printFloats()



