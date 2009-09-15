# Trim C compiler installation to a minimum

import strutils, os

proc newName(f: string): string = 
  return extractDir(f) / "trim_" & extractFilename(f)

proc walker(dir: string) = 
  for kind, path in walkDir(dir):
    case kind
    of pcFile:
      moveFile(newName(path), path)
      # test if installation still works:
      if executeShellCommand(r"nimrod c --force_build tests\tlastmod") == 0:
        echo "Optional: ", path
        removeFile(newName(path))
      else:
        echo "Required: ", path
        # copy back:
        moveFile(path, newName(path))
    of pcDirectory:
      walker(path)
    else: nil

if paramCount() == 1:
  walker(paramStr(1))
else:
  echo "Usage: trimcc c_compiler_directory"
