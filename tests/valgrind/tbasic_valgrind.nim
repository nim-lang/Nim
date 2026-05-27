discard """
  valgrind: true
  cmd: "nim c --gc:destructors $file"
  disabled: "arm64"
"""

echo "hello world"
