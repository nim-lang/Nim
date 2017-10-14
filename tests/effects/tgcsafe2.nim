discard """
  errormsg: ''' (proc (s: string) = res &= &(s, "abc"), nil) is not GC safe'''
  line: 11
"""
#5620
var res = ""

proc takeCallback(foo: (proc(s: string) {.gcsafe.})) =
  foo "string"

takeCallback(proc (s: string) =
  res &= s & "abc")
