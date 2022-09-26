discard """
output: '''
Subobject test called
5
'''
"""

type
  TClassOfTCustomObject {.pure, inheritable.} = object
    base* : ptr TClassOfTCustomObject
    className* : string
  TClassOfTobj = object of TClassOfTCustomObject
    nil
  TCustomObject {.inheritable.} = ref object
    class* : ptr TClassOfTCustomObject
  TObj = ref object of TCustomObject
    data: int

var ClassOfTObj: TClassOfTObj

proc initClassOfTObj() =
  ClassOfTObj.base = nil
  ClassOfTObj.className = "TObj"

initClassOfTObj()

proc initialize*(self: TObj) =
  self.class = addr ClassOfTObj
  # this generates wrong C code: && instead of &

proc newInstance(T: typedesc): T =
  mixin initialize
  new(result)
  initialize(result)

var o = TObj.newInstance()

type
    TestObj* = object of RootObj
        t:int
    SubObject* = object of TestObj

method test*(t:var TestObj) {.base.} =
    echo "test called"

method test*(t:var SubObject) =
    echo "Subobject test called"
    t.t= 5

var a: SubObject

a.test()
echo a.t
