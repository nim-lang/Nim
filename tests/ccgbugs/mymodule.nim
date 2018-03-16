type
  MyRefObject* = ref object
    s: string


proc newMyRefObject*(s: string): MyRefObject =
  new(result)
  result.s = s
  
proc `$`*(o: MyRefObject): string =
  o.s
  