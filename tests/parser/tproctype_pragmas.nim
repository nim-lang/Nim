discard """
  output: '''39
40'''
"""

# bug 1802
# Ensure proc pragmas are attached properly:

proc makeStdcall(s: string): (proc(i: int) {.stdcall.}) =
  (proc (x: int) {.stdcall.} = echo x)

proc makeNimcall(s: string): (proc(i: int)) {.stdcall.} =
  (proc (x: int) {.nimcall.} = echo x)

let stdc: proc (y: int) {.stdcall.} = makeStdcall("bu")
let nimc: proc (y: int) {.closure.} = makeNimcall("ba")

stdc(39)
nimc(40)
