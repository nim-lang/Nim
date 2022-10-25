type ProcType = proc()

const a: ProcType = proc() = discard
const arr: array[8, ProcType] = [a, a, a, a, a, a, a, a]

for i in 0..<arr.len:
  doAssert arr[i].isNil == false
