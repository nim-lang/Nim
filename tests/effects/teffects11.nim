discard """
action: compile
errormsg: "type mismatch: got <proc (x: int){.gcsafe.}>"
line: 21
"""

type
  Effect1 = object
  Effect2 = object
  Effect3 = object

proc test(fnc: proc(x: int): void {.forbids: [Effect2].}) {.tags: [Effect1, Effect3, RootEffect].} =
  fnc(1)

proc t1(x: int): void = echo $x
proc t2(x: int): void {.tags: [Effect2].} = echo $x
proc t3(x: int): void {.tags: [Effect3].} = echo $x

test(t1)
test(t3)
test(t2)
