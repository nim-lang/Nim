type SomeRefObj = ref object of RootObj
  someIntMember: int

proc createSomeRefObj(v: int): SomeRefObj=
  result.new()
  result.someIntMember = v

const compileTimeSeqOfRefObjs = @[createSomeRefObj(100500), createSomeRefObj(2)]