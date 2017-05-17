discard """
  file: "tnotuniquename/mnotuniquename.nim"
  errormsg: "module names need to be unique per Nimble package"
"""

import mnotuniquename
import tnotuniquename/mnotuniquename
