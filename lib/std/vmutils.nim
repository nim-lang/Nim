##[
Experimental API, subject to change.
]##

proc vmTrace*(on: bool) {.compileTime.} =
  runnableExamples:
    static: vmTrace(true)
    proc fn =
      var a = 1
      vmTrace(false)
    static: fn()
