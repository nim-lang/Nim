type ProcType = proc():int
let a: ProcType = proc():int = 1
let b: array[1, ProcType] = [a]

const something: ProcType = proc():int = 2
let arr: array[1, ProcType] = [something]
doAssert arr[0]() == 2
