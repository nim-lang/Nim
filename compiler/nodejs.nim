import os

proc findNodeJs*(): string =
  result = findExe("nodejs")
  if result == "":
    result = findExe("node")
  if result == "":
    result = findExe("iojs")

