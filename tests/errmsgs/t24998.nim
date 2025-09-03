discard """
  matrix: "--hintaserror:DuplicateModuleImport"
  errormsg: "duplicate import of 'ma' [DuplicateModuleImport]"
"""

import dep1/ma
import dep2/ma
import dep1/ma