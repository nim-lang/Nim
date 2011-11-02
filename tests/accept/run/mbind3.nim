# Module A
var 
  lastId = 0

template genId*: expr =
  bind lastId
  inc(lastId)
  lastId


