discard """
  file: "tbasicresult.nim"
  output: "Traceback (most recent call last)\ntbasicresult.nim(17)     tbasicresult\ntbasicresult.nim(15)     err\n\nBacktrace:\ntbasicresult.nim(17)     tbasicresult\n\nError: my error [Exception]"
"""

import results

let five = just(5)
assert five.isSuccess
assert five.get == 5
assert(not five.isError)
assert(not just().isError)

proc err(): int =
  raise newException(Exception, "my error")

let errR = catchError(err())
assert errR.isError
assert $errR == "error(my error)"
errR.printError
