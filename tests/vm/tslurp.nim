import os

template getScriptDir(): string =
  parentDir(instantiationInfo(-1, true).filename)

const
  relRes = slurp"./tslurp.nim"
  absRes = slurp(getScriptDir() / "tslurp.nim")

doAssert relRes.len > 200
doAssert absRes.len > 200
doAssert relRes == absRes
