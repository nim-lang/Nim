discard """
  cmd: "nim c --compileOnly --os:standalone --exceptions:quirky -d:noSignalHandler -d:danger $file"
  action: "compile"
"""

echo "hi"
