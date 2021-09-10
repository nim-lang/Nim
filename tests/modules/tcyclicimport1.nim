discard """
  output: '''abchi'''
  cmd: "nim c --experimental:cyclicImports -d:nimYes $file"
"""

when defined(nimYes):
  import mcyclicimport1

type
  Foo* = object
    a, b: int
    o: ref Other

proc foo =
  bar("abc")
  var f: Foo
  f.a = 3

foo()

proc bar(s: string) =
  for i in 0..<s.len:
    stdout.write s[i]
  echo "hi"
