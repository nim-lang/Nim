discard """
  errormsg: "cannot evaluate at compile time: error"
"""

static: # bug #23827
  # Forward-declaring procedure (let's call this proc "A")
  proc error() {.raises: [].}

  # called in another function (let's call this proc "B")
  proc env(key: string, default: string = ""): string {.raises: [].} =
    error()

  # A used before its implmentation
  # removing this line fixes the issue
  let DESTDIR = env("", "")

  # later, A's implementation uses B
  proc error() = discard env("", "")
