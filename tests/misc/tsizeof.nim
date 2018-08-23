discard """
  file: "tsize.nim"
  output: "40 3 12 32"
"""
type
  TMyRecord {.final.} = object
    x, y: int
    b: bool
    r: float
    s: string

  TMyEnum = enum
    tmOne, tmTwo, tmThree, tmFour

  TMyArray1 = array[3, uint8]
  TMyArray2 = array[1..3, int32]
  TMyArray3 = array[TMyEnum, float64]

const 
  mysize1 = sizeof(TMyArray1)
  mysize2 = sizeof(TMyArray2)
  mysize3 = sizeof(TMyArray3)

write(stdout, sizeof(TMyRecord))
echo ' ', mysize1, ' ', mysize2, ' ',mysize3



