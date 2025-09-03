discard """
  matrix: "--hintaserror:DuplicateModuleImport"
  errormsg: "duplicate import of 'ma'; previous import here: t24998.nim(6, 13) [DuplicateModuleImport]"
"""

import dep1/ma
import dep2/ma
import dep1/ma