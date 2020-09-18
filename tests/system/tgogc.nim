discard """
  disabled: "windows"
  cmd: "nim c --gc:go $file"
  action: "compile"
"""
# bug #11447
echo "Go GC test"
