discard """
  file: "ttypeimportfail.nim"
  errormsg: "undeclared identifier: 'colBlue'"
"""

{.experimental: "typeImports".}

from colors import Color

# constants of the type not imported
discard colBlue
