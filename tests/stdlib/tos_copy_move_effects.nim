discard """
  action: "compile"
"""

# Moving and copying files report failures as `OSError` or `IOError`, so
# callers can list exactly those instead of `Exception`.

import std/os

proc moveOne() {.raises: [OSError, IOError].} =
  moveFile("source", "dest")

proc copyOne() {.raises: [OSError, IOError].} =
  copyFileWithPermissions("source", "dest", ignorePermissionErrors = false)

proc copyTree() {.raises: [OSError, IOError].} =
  copyDirWithPermissions("source", "dest", ignorePermissionErrors = false)
