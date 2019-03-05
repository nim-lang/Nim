discard """
joinable: false
target: "C"
"""

type
  O = object

var dCalls = 0

proc `=destroy`(x: var O) = inc dCalls
proc `=sink`(x: var O, y: O) = doAssert false

proc newO(): O = discard

proc main() =
  doAssert dCalls == 0
  discard newO()
  doAssert dCalls == 1
  discard newO()
  doAssert dCalls == 2

main()
