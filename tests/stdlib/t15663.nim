discard """
  cmd: "nim c --gc:arc $file"
  output: "Test"
"""

import std/widestrs

let ws = newWideCString("Test")
echo ws
