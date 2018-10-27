import os

template getScriptDir(): string =
  parentDir(instantiationInfo(-1, true).filename)

const
  relRes = slurp"../dummy.txt"
  absRes = slurp(parentDir(getScriptDir()) / "dummy.txt")

echo relRes
echo absRes

