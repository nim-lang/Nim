type
  MyRefObject* = ref object
    s: string
  
  BaseObj* = ref object of RootObj
  ChildObj* = ref object of BaseObj

proc newMyRefObject*(s: string): MyRefObject =
  new(result)
  result.s = s
  
proc `$`*(o: MyRefObject): string =
  o.s
  