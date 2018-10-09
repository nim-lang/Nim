macro testMacro(body: untyped): untyped = discard
macro testMacro(s: string, body: untyped): untyped = discard
proc foo() {.testMacro: "foo".} = discard
