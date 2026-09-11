discard """
matrix: "--legacy:importcNoSideEffect"
"""

proc cProc() {.importc.}

func wrapper() =
  cProc()

