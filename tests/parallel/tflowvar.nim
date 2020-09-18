discard """
  output: '''foobarfoobar
bazbearbazbear

1'''
  cmd: "nim $target --threads:on $options $file"
  disabled: "openbsd"
"""

import threadpool

proc computeSomething(a, b: string): string = a & b & a & b & "\n"

proc main =
  let fvA = spawn computeSomething("foo", "bar")
  let fvB = spawn computeSomething("baz", "bear")

  echo(^fvA, ^fvB)

main()
sync()


type
  TIntSeq = seq[int]

proc t(): TIntSeq =
  result = @[1]

proc p(): int =
  var a: FlowVar[TIntSeq]
  parallel:
    var aa = spawn t()
    a = aa
  result = (^a)[0]

echo p()
