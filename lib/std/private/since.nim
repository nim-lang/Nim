##[
`since` is used to emulate older versions of nim stdlib with `--useVersion`,
see `tuse_version.nim`.

If a symbol `foo` is added in version `(1,3,5)`, use `{.since: (1.3.5).}`, not
`{.since: (1.4).}`, so that it works in devel in between releases.

The emulation cannot be 100% faithful and to avoid adding too much complexity,
`since` is not needed in those cases:
* if a new module is added
* if an overload is added
* if an extra parameter to an existing routine is added
]##

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
