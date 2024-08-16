discard """
action: compile
errormsg: "type mismatch: got <proc (i: int){.gcsafe.}>"
line: 23
"""

type MyEffect = object
type ProcType1 = proc (i: int): void {.forbids: [MyEffect].}
type ProcType2 = proc (i: int): void

proc caller1(p: ProcType1): void = p(1)
proc caller2(p: ProcType2): void = p(1)

proc effectful(i: int): void {.tags: [MyEffect].} = echo $i
proc effectless(i: int): void {.forbids: [MyEffect].} = echo $i

proc toBeCalled1(i: int): void = effectful(i)
proc toBeCalled2(i: int): void = effectless(i)

caller1(toBeCalled2)
caller2(toBeCalled1)
caller2(toBeCalled2)
caller1(toBeCalled1)
