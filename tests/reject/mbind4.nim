# Module A
var 
  lastId = 0

template genId*: expr =
  inc(lastId)
  lastId


