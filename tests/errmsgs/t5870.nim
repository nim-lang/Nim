# bug #5870
type SomeRefObj = ref object of RootObj
    someIntMember: int

proc createSomeRefObj(v: int): SomeRefObj=
    result.new()
    result.someIntMember = v

const compileTimeSeqOfRefObjs = @[createSomeRefObj(100500), createSomeRefObj(2)]

doAssert compileTimeSeqOfRefObjs[0].someIntMember == 100500
doAssert compileTimeSeqOfRefObjs[1].someIntMember == 2
