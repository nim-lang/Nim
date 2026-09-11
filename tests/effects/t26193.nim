discard """
errormsg: "'wrapper' can have side effects"
"""

proc cProc() {.importc.}

func wrapper() =
  cProc()
