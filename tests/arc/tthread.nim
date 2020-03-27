discard """
  cmd: "nim c --gc:arc --threads:on $file"
  nimout: "ok"
"""
import threadpool, os

proc thread(): string =
  os.sleep(1000)
  return "ok"

var fv = spawn thread()
sync()
echo ^fv