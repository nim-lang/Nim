discard """
  errormsg: "'.cyclic' import of a module that imports this module without '.cyclic'; annotate that import with '{.cyclic.}' too:"
  file: "mcyclic_onesided.nim"
"""

# the cycle is entered via a plain import, so it is too late for `.cyclic`:
import mcyclic_onesided

proc fa*(): int = 1

echo fb()
