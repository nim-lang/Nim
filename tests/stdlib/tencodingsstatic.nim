discard """
  targets: "c cpp"
  disabled: "windows"
  matrix: "--mm:refc; --mm:orc"
"""

import std/[assertions, encodings]

when defined(linux):
  {.passl: "-static".}

block:
  let encoder = open("UTF-8", "CP1252")
  defer: encoder.close()
  doAssert encoder.convert("caf\xE9") == "café"
  doAssert encoder.convert("") == ""
  doAssert encoder.convert("\x80") == "€"
doAssert convert("café", "CP1252", "UTF-8") == "caf\xE9"
doAssertRaises(EncodingError):
  discard open("invalid-encoding", "UTF-8")
