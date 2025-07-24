proc foo(x: Natural or SomeUnsignedInt):int = 
  when x is int:
    result = 1
  else:
    result = 2
let a = 10
doAssert foo(a) == 1

let b = 10'u8
doAssert foo(b) == 2