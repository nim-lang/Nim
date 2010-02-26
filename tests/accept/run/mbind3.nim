# Module A
var 
  lastId = 0

template genId*: expr =
  inc(bind lastId)
  lastId


