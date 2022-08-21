discard """
  cmd: "nim c --gc:arc $file"
  output: "Test"
"""

let ws = newWideCString("Test")
echo ws