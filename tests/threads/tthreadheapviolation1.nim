discard """
  errormsg: "'horrible' is not GC-safe"
  line: 11
  cmd: "nim $target --hints:on --threads:on $options $file"
"""

var
  global: string = "test string"
  t: Thread[void]

proc horrible() {.thread.} =
  global = "string in thread local heap!"
  var x = global
  var mydata = (x, "my string too")
  echo global

createThread[void](t, horrible)
joinThread(t)
