discard """
  line: 15
  errormsg: "'mainUnsafe' is not GC-safe"
"""

proc mymap(x: proc ()) =
  x()

var
  myglob: string

proc mainSafe() {.gcsafe.} =
  mymap(proc () = echo "foo")

proc mainUnsafe() {.gcsafe.} =
  mymap(proc () = myglob = "bar"; echo "foo", myglob)
