


#------------------------------------------------------------------------------
## Useful Constants
const NULL* = 0


#------------------------------------------------------------------------------
## Memory Utility Functions

proc newHeap*[T](): ptr T =
  result = cast[ptr T](alloc0(sizeof(T))) 

proc copyNew*[T](x: var T): ptr T =
  var 
    size = sizeof(T)    
    mem = alloc(size)  
  copyMem(mem, x.addr, size)  
  return cast[ptr T](mem)

proc copyTo*[T](val: var T, dest: int) = 
  copyMem(pointer(dest), val.addr, sizeof(T))    

proc allocType*[T](): pointer = alloc(sizeof(T)) 

proc newShared*[T](): ptr T =
  result = cast[ptr T](allocShared0(sizeof(T))) 

proc copyShared*[T](x: var T): ptr T =
  var 
    size = sizeof(T)    
    mem = allocShared(size)  
  copyMem(mem, x.addr, size)  
  return cast[ptr T](mem)

#------------------------------------------------------------------------------
## Pointer arithmetic 

proc `+`*(p: pointer, i: int): pointer {.inline.} =
  cast[pointer](cast[int](p) + i)