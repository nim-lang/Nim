discard """
  errormsg: "'mainUnsafe' is not GC-safe"
  line: 17
  cmd: "nim $target --hints:on --threads:on $options $file"
"""

proc mymap(x: proc ()) =
  x()

var
  myglob: string

proc mainSafe() {.gcsafe.} =
  mymap(proc () = echo "foo")

proc mainUnsafe() {.gcsafe.} =
  mymap(proc () = myglob = "bar"; echo "foo", myglob)
