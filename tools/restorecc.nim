
import os, strutils

proc main(dir: string, wanted: string) =
  for kind, path in walkDir(dir):
    case kind
    of pcFile:
      let name = extractFilename(path)
      if name == wanted:
        let newLoc = path.replace("mingw_backup", "mingw")
        echo "creating ", newLoc
        copyFile(path, newLoc)
    of pcDir: main(path, wanted)
    else: discard

main("dist/mingw_backup", paramStr(1))
