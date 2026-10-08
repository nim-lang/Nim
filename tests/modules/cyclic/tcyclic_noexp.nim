discard """
  errormsg: "'.cyclic' imports require '--experimental:cyclicImports'"
  file: "tcyclic_noexp.nim"
"""

import mcyclic_dummy {.cyclic.}
