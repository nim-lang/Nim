import os
block getCurrentPkgDir:
  static: doAssert getCurrentPkgDir() == currentSourcePath.parentDir.parentDir
