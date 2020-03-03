# Module A
var
  lastId = 0

template genId*: int =
  bind lastId
  inc(lastId)
  lastId


