discard """
  action: "compile"
  matrix: "-d:ssl"
"""

# Loading a library reports `nil`, not an exception, so procs that only load
# libraries can be checked with an empty or narrow `raises` list.

import std/dynlib

proc loadByPattern() {.raises: [].} =
  discard loadLibPattern("libnonexistent(|.1).so")

proc lookUp(lib: LibHandle) {.raises: [LibraryError].} =
  discard checkedSymAddr(lib, "nonexistent")

when defined(ssl):
  import std/[net, httpclient]

  proc createContext() {.raises: [SslError, IOError, OSError, LibraryError].} =
    discard newContext(verifyMode = CVerifyPeer)

  proc createClient() {.raises: [CatchableError].} =
    newHttpClient().close()
