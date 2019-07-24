import os

proc findNodeJs*(): string {.inline.} =
  ## Find NodeJS executable and return it as a string.
  result = findExe("nodejs")
  if result == "":
    result = findExe("node")
