discard """
  errormsg: "'.cyclic' import of a module that imports this module without '.cyclic'; annotate that import with '{.cyclic.}' too:"
  file: "moverlap_c.nim"
"""

# `moverlap_a` belongs to the group of this module and is being checked
# together with it, even though it is not on the import stack when this
# module imports `moverlap_c`: `moverlap_c`'s `.cyclic` import of it closes a
# cycle that was entered via a plain import.
import overlap/moverlap_a {.cyclic.}
import overlap/moverlap_c

proc fb*(): int = fa() + 1
proc fcc*(): int = fc()
