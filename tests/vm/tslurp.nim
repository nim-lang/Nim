import os

template getScriptDir(): string =
  parentDir(instantiationInfo(-1, true).filename)

const
  relRes = slurp"./tslurp.nim"
  absRes = slurp(getScriptDir() / "tslurp.nim")

echo relRes
echo absRes

