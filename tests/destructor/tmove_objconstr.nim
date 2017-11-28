
discard """
output:  '''test created
test destroyed 0'''
  cmd: '''nim c --newruntime $file'''
"""

# bug #4214
type
  Data = object
    data: string
    rc: int

proc `=destroy`(d: var Data) =
  dec d.rc
  echo d.data, " destroyed ", d.rc

proc `=`(dst: var Data, src: Data) =
  echo src.data, " copied"
  dst.data = src.data & " (copy)"
  dec dst.rc
  inc dst.rc

proc initData(s: string): Data =
  result = Data(data: s, rc: 1)
  echo s, " created"

proc main =
  var x = initData"test"

when isMainModule:
  main()
