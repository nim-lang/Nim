from strutils import endsWith, split
from os import isAbsolute

proc checkMsg*(msg, expectedEnd, name: string)=
  let filePrefix = msg.split(' ', maxSplit = 1)[0]
  if not filePrefix.isAbsolute:
    echo name, ":not absolute: `", msg & "`"
  elif not msg.endsWith expectedEnd:
    echo name, ":expected suffix:\n`" & expectedEnd & "`\ngot:\n`" & msg & "`"
  else:
    echo name, ":ok"

