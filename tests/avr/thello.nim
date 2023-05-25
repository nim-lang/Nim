discard """
  cmd: "nim c --compileOnly --os:standalone --exceptions:goto -d:noSignalHandler -d:danger --threads:off $file"
  action: "compile"
"""

echo "hi"
