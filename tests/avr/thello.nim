discard """
  cmd: "nim c --os:standalone --exceptions:quirky -d:noSignalHandler -d:danger $file"
  action: "compile"
"""

echo "hi"
