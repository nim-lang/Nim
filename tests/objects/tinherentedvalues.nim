discard """
  output: '''tbObj of TC true
true
5'''
"""

# bug #1053
type
  TA = object of TObject
    a: int

  TB = object of TA
    b: int

  TC = object of TB
    c: int

proc test(p: TA) =
  #echo "p of TB ", p of TB
  if p of TB:
    #var tbObj = TB(p)

    # tbObj is actually no longer compatible with TC:
    echo "tbObj of TC ", p of TC

var v = TC()
v.a = 1
v.b = 2
v.c = 3
test(v)


# bug #924
type
  MyObject = object of TObject
    x: int

var
  asd: MyObject

proc isMyObject(obj: TObject) =
    echo obj of MyObject
    if obj of MyObject:
        let a = MyObject(obj)
        echo a.x

asd.x = 5

#var asdCopy = TObject(asd)
#echo asdCopy of MyObject

isMyObject(asd)
#isMyObject(asdCopy)
