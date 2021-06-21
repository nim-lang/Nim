discard """
  cmd: '''nim c --gc:arc $file'''
  output: '''no crash'''
"""

# bug #11205

type
  MyEnum = enum
    A, B, C
  MyCaseObject = object
    case kind: MyEnum
    of A: iseq: seq[int]
    of B: fseq: seq[float]
    of C: str: string


  MyCaseObjectB = object # carefully constructed to use the same enum,
                         # but a different object type!
    case kind: MyEnum
    of A, C: x: int
    of B: fseq: seq[float]


var x = MyCaseObject(kind: A)
x.iseq.add 1
#x.kind = B
#x.fseq.add -3.0

var y = MyCaseObjectB(kind: A)
y.x = 1
y.kind = C
echo "no crash"


#################
## bug #12821

type
  RefBaseObject* = ref object of RootObj
    case kind: bool
      of true: a: int
      of false: b: float

  MyRefObject = ref object of RefBaseObject
    x: float

let z = new(MyRefObject)
z.kind = false
