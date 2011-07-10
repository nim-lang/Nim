var 
  global: string = "test string"
  t: TThread[string]

proc horrible() {.thread.} =
  global = "string in thread local heap!"
  var x = global
  var mydata = (x, "my string too")
  echo global

createThread(t, horrible)
joinThread(t)


