
from os import getHomeDir, `/`

proc logStr*(line: string) =
  var f: File
  if open(f, getHomeDir() / "nimsuggest.log", fmAppend):
    f.writeLine(line)
    f.close()

