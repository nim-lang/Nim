import os

proc findNodeJs*(): string =
  result = findExe("nodejs")
  if result == "":
    result = findExe("node")
