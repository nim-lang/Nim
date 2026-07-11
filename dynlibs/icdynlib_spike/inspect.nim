import std/os
import bifexports

for item in readDynlibExports(paramStr(1)):
  echo item.nimName, "\t", item.externalName
