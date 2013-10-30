# Trim C compiler installation to a minimum

import strutils, os

proc newName(f: string): string =
  var (dir, name, ext) = splitFile(f)
  return dir / "trim_" & name & ext

proc walker(dir: string) =
  for kind, path in walkDir(dir):
    case kind
    of pcFile:
      moveFile(dest=newName(path), source=path)
      # test if installation still works:
      if execShellCmd(r"nimrod c --force_build koch") == 0:
        echo "Optional: ", path
        removeFile(newName(path))
      else:
        echo "Required: ", path
        # copy back:
        moveFile(dest=path, sourc=newName(path))
    of pcDir:
      walker(path)
    else: nil

if paramCount() == 1:
  walker(paramStr(1))
else:
  quit "Usage: trimcc c_compiler_directory"
