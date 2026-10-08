discard """
  matrix: "--experimental:cyclicImports"
  errormsg: "'.cyclic' imports must be unconditional top-level statements"
  file: "tcyclic_when.nim"
"""

when true:
  import mcyclic_dummy {.cyclic.}
