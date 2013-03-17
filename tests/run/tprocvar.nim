discard """
  file: "tprocvar.nim"
  output: "papbpcpdpe7"
"""
# test variables of type proc

proc pa() {.cdecl.} = write(stdout, "pa")
proc pb() {.cdecl.} = write(stdout, "pb")
proc pc() {.cdecl.} = write(stdout, "pc")
proc pd() {.cdecl.} = write(stdout, "pd")
proc pe() {.cdecl.} = write(stdout, "pe")

const
  algos = [pa, pb, pc, pd, pe]

var
  x: proc (a, b: int): int {.cdecl.}

proc ha(c, d: int): int {.cdecl.} =
  echo(c + d)
  result = c + d

for a in items(algos):
  a()

x = ha
discard x(3, 4)

#OUT papbpcpdpe7



