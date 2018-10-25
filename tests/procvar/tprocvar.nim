discard """
  output: '''
papbpcpdpe7
'''
"""

block genericprocvar:
  proc foo[T](thing: T) =
    discard thing
  var a: proc (thing: int) {.nimcall.} = foo[int]


block tprocvar2:
  proc pa() {.cdecl.} = write(stdout, "pa")
  proc pb() {.cdecl.} = write(stdout, "pb")
  proc pc() {.cdecl.} = write(stdout, "pc")
  proc pd() {.cdecl.} = write(stdout, "pd")
  proc pe() {.cdecl.} = write(stdout, "pe")

  const algos = [pa, pb, pc, pd, pe]
  var x: proc (a, b: int): int {.cdecl.}

  proc ha(c, d: int): int {.cdecl.} =
    echo(c + d)
    result = c + d

  for a in items(algos):
    a()

  x = ha
  discard x(3, 4)


block tprocvars:
  proc doSomething(v: int, x: proc(v:int):int): int = return x(v)
  proc doSomething(v: int, x: proc(v:int)) = x(v)

  doAssert doSomething(10, proc(v: int): int = return v div 2) == 5

