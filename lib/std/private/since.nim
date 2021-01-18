template since*(version: (int, int), body: untyped) {.dirty.} =
  ## Evaluates `body` if the ``(NimMajor, NimMinor)`` is greater than
  ## or equal to `version`. Usage:
  ##
  ## .. code-block:: Nim
  ##   proc fun*() {.since: (1, 3).}
  ##   since (1, 3): fun()
  when (NimMajor, NimMinor) >= version:
    body

template since*(version: (int, int, int), body: untyped) {.dirty.} =
  ## Evaluates `body` if ``(NimMajor, NimMinor, NimPatch)`` is greater than 
  ## or equal to `version`. Usage:
  ##
  ## .. code-block:: Nim
  ##   proc fun*() {.since: (1, 3, 1).}
  ##   since (1, 3, 1): fun()
  when (NimMajor, NimMinor, NimPatch) >= version:
    body