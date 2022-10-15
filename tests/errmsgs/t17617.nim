discard """
  errormsg: "type mismatch: got <template (x: int): int>"
"""

template foo(x:int):int = discard
proc bar(p:proc(x:int):int) = discard
#void return type gives identical crash,i.e.
#template foo(x:int) = discard; proc bar(p:proc(x:int)) = discard
#same crash with macro foo(args..)
bar(foo)