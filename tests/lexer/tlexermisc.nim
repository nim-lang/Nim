discard """
  action: run
  output: "equal"
"""

var t=0x950412DE

if t==0x950412DE:
    echo "equal"
else:
    echo "not equal"

type
  TArray = array[0x0012..0x0013, int]

var a: TArray

doAssert a[0x0012] == 0


# #7884

type Obj = object
    ö: int

let o = Obj(ö: 1)
doAssert o.ö == 1
