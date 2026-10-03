discard """
  cmd: "nim check --hints:off $file"
  errormsg: "'del' can have side effects"
  file: "system.nim"
"""

type MyObject = object

proc `=destroy`(v: var MyObject) =
  echo "hello"

func remove(v: var seq[MyObject]) =
  v.del(0)
