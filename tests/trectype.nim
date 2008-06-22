# Test recursive type descriptions
# (mainly for the C code generator)

type
  PA = ref TA
  TA = array [0..2, PA]

  PRec = ref TRec
  TRec = record
    a, b: TA

  P1 = ref T1
  PB = ref TB
  TB = array [0..3, P1]
  T1 = array [0..6, PB]
