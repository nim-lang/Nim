discard """
  cmd: "nim $target --threads:on $options $file"
  errormsg: "illegal recursion in type 'Executor'"
  line: 8
"""

type
  ExecutorObj[N] = object
    tasks: seq[N]

  Executor[N] = Executor[N]

var e: Executor[int]
