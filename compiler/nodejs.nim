import os

proc findNodeJs*(): string {.inline.} =
  ## Find NodeJS executable and return it as a string.
  result = findExe("nodejs")
  if result.len == 0:
    result = findExe("node")
  if result.len == 0:
    echo "Please install NodeJS first, see https://nodejs.org/en/download"
    raise newException(IOError, "NodeJS not found in PATH: " & result)
