discard """
  valgrind: true
  cmd: "nim c --gc:destructors $file"
"""

echo "hello world"
