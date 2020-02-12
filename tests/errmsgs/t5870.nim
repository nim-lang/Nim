discard """
errormsg: "invalid type for const: seq[SomeRefObj]"
line: 14
"""

# bug #5870
type SomeRefObj = ref object of RootObj
    someIntMember: int

proc createSomeRefObj(v: int): SomeRefObj=
    result.new()
    result.someIntMember = v

const compileTimeSeqOfRefObjs = @[createSomeRefObj(100500), createSomeRefObj(2)]

for i in 0..1:
  echo compileTimeSeqOfRefObjs[i].someIntMember
