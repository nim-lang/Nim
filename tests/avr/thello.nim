discard """
  cmd: "nim c --compileOnly --os:standalone --exceptions:quirky -d:noSignalHandler -d:danger --threads:off $file"
  action: "compile"
"""

echo "hi"
