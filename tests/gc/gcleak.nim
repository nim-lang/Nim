type
  TTestObj = object of TObject
    x: string

proc MakeObj(): TTestObj =
  result.x = "Hello"

while true:
  var obj = MakeObj()


