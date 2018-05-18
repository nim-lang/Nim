discard """
ccodeCheck: "\\i @'__attribute__((noreturn))' .*"
"""

proc noret1*(i: int) {.noreturn.} =
  echo i


proc noret2*(i: int): void {.noreturn.} =
  echo i

noret1(1)
noret2(2)

var p {.used.}: proc(i: int): int
doAssert(not compiles(
  p = proc(i: int): int {.noreturn.} = i # noreturn lambda returns int
))


doAssert(not compiles(
  block:
    noret1(5)
    echo 1 # statement after noreturn
))
