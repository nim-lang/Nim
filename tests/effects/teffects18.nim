discard """
action: compile
errormsg: "type mismatch: got <ProcType2>"
line: 19
"""

type MyEffect = object
type ProcType1 = proc (i: int): void {.forbids: [MyEffect].}
type ProcType2 = proc (i: int): void

proc testFunc(p: ProcType1): void = p(1)

proc toBeCalled(i: int): void {.tags: [MyEffect].} = echo $i

let emptyTags = proc(i: int): void {.tags: [].} = echo $i
let noTags: ProcType2 = proc(i: int): void = toBeCalled(i)

testFunc(emptyTags)
testFunc(noTags)
