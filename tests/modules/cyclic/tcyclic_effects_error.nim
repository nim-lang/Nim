discard """
  errormsg: "fb(x - 1) can raise an unlisted exception: ref ValueError"
  file: "tcyclic_effects_error.nim"
"""

import mcyclic_effects_error {.cyclic.}

proc fa*(x: int): int {.raises: [].} = (if x > 0: fb(x - 1) else: 0)
