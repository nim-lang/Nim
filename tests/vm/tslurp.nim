import os

template getScriptDir(): string =
  parentDir(instantiationInfo(-1, true).filename)

const
  relRes = slurp"../../readme.txt"
  absRes = slurp(parentDir(parentDir(getScriptDir())) / "readme.txt")
  
echo relRes
echo absRes

