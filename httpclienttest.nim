# Small test program to test httpclient i.e. for IPv6

from httpclient import downloadFile
from os import existsEnv, getEnv, getAppFilename

if not existsEnv("uri") or not existsEnv("dest"):
  raise newException(OSError, "Usage: uri=X dest=Y " & getAppFilename())

downloadFile(getEnv("uri"),getEnv("dest"))
