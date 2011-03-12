type
  TTestObj = object of TObject
    x: string
    s: seq[int]

proc MakeObj(): TTestObj =
  result.x = "Hello"
  result.s = @[1,2,3]

#while true:
#  var obj = MakeObj()
#  echo GC_getstatistics()

proc inProc() = 
  while true:
    var obj: TTestObj
    obj = MakeObj()

inProc()

