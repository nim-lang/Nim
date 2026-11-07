discard """
  errormsg: "undeclared identifier: 'missing'"
  file: "tfrom_import_error.nim"
  line: 7
"""

from forms/mfrom_import_error {.cyclic.} import fb, missing

proc fa*(): int = 1
echo fb()
