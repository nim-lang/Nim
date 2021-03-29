discard """
  disabled: "unix"
  matrix: "--gc:refc; --gc:arc"
"""

when defined(windows):
  import std/registry

  block: # bug #14010
    let path = "Environment"
    let key = "D20210328T202842_key"
    let val = "D20210328T202842_val"
    let handle = HKEY_CURRENT_USER
    setUnicodeValue("Environment", key, val, handle)
    doAssert getUnicodeValue(path, key, handle) == val
