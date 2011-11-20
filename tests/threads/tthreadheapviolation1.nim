discard """
  line: 12
  errormsg: "write to foreign heap"
  cmd: "nimrod cc --hints:on --threads:on $# $#"
"""

var 
  global: string = "test string"
  t: TThread[void]

proc horrible() {.thread.} =
  global = "string in thread local heap!"
  var x = global
  var mydata = (x, "my string too")
  echo global

createThread[void](t, horrible)
joinThread(t)


