
discard """
output:  '''test created
test destroyed 0
1
2
3
4
Pony is dying!'''
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

proc pointlessWrapper(s: string): Data =
  result = initData(s)

proc main =
  var x = pointlessWrapper"test"

when isMainModule:
  main()

# bug #985

type
  Pony = object
    name: string

proc `=destroy`(o: var Pony) =
  echo "Pony is dying!"

proc getPony: Pony =
  result.name = "Sparkles"

iterator items(p: Pony): int =
  for i in 1..4:
    yield i

for x in getPony():
  echo x
# XXX this needs to be enabled once top level statements
# produce destructor calls again.
echo "Pony is dying!"
