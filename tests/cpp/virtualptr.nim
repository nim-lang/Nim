type 
  Loo* {.exportc.} = object
  LooPtr* = ptr Loo
  Moo* {.exportc.} = object 
    loo*: LooPtr


proc salute*(foo: LooPtr) {.virtual.} = 
  discard 
