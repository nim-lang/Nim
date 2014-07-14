discard """
  output: '''foobarfoobarbazbearbazbear'''
  cmd: "nimrod $target --threads:on $options $file"
"""

import threadpool

proc computeSomething(a, b: string): string = a & b & a & b

proc main =
  let fvA = spawn computeSomething("foo", "bar")
  let fvB = spawn computeSomething("baz", "bear")

  echo(^fvA, ^fvB)

main()
sync()
