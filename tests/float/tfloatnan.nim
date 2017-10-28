discard """
  file: "tfloatnan.nim"
  output: '''Nim: nan
Nim: nan (float)
C: nan (float)
Nim: nan (double)
C: nan (double)
'''
"""

proc printf(formatstr: cstring): int {.importc: "printf", varargs, header: "<stdio.h>".}

let f = NaN
echo "Nim: ", f

let f32: float32 = NaN
echo "Nim: ", f32, " (float)"
discard printf("C: %f (float)\n", f32)

let f64: float64 = NaN
echo "Nim: ", f64, " (double)"
discard printf("C: %lf (double)\n", f64)
