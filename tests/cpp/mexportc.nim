{.used.} # ideally, would not be needed

var fun0 {.exportc.} = 10
proc fun1() {.exportc.} = discard
proc fun2() {.exportc: "$1".} = discard
proc fun3() {.exportc: "fun3Bis".} = discard

when defined cpp:
  proc funx1() {.exportcpp.} = discard
