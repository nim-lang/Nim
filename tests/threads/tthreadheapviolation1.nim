discard """
  line: 12
  errormsg: "write to foreign heap"
  cmd: "nimrod $target --hints:on --threads:on $options $file"
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


