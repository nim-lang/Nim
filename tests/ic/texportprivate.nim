discard """
output: '''42'''
"""

# `export s` re-exports a symbol whose declaration has no `*`. It reaches the
# module interface through `reexportSym` alone, so a NIF writer that decides
# importability from `sfExported` ships it as private and the importer reports
# "undeclared identifier". `std/random` does exactly this
# (`proc initRand(): Rand` + `since (1, 5, 1): export initRand`), which made
# `--ic:on` unable to compile anything reaching `std/tempfiles`.

import mexportprivate

echo hidden()
