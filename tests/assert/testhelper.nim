from strutils import endsWith, split
from os import isAbsolute

proc checkMsg*(msg, expectedEnd, name: string, absolute = true)=
  let filePrefix = msg.split(' ', maxSplit = 1)[0]
  if absolute and not filePrefix.isAbsolute:
    echo name, ":not absolute: `", msg & "`"
  elif not msg.endsWith expectedEnd:
    echo name, ":expected suffix:\n`" & expectedEnd & "`\ngot:\n`" & msg & "`"
  else:
    echo name, ":ok"

