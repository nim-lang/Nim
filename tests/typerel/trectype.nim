discard """
  errormsg: "internal error: cannot generate C type for: PA"
  disabled: true
"""
# Test recursive type descriptions
# (mainly for the C code generator)

type
  PA = ref TA
  TA = array[0..2, PA]

  PRec = ref TRec
  TRec {.final.} = object
    a, b: TA

  P1 = ref T1
  PB = ref TB
  TB = array[0..3, P1]
  T1 = array[0..6, PB]

var
  x: PA
new(x)
#ERROR_MSG internal error: cannot generate C type for: PA
