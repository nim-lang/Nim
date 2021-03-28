discard """
  disabled: "unix"
  matrix: "--gc:refc; --gc:arc"
"""

import std/registry

# bug #14010
setUnicodeValue(r"Environment", "fakePath", "flywind", HKEY_CURRENT_USER)
