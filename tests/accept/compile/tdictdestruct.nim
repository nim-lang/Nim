
type
  TDict[TK, TV] = object
    k: TK
    v: TV
  PDict[TK, TV] = ref TDict[TK, TV]

proc destroyDict[TK, TV](a : PDict[TK, TV]) =
    return
proc newDict[TK, TV](a: TK, b: TV): PDict[TK, TV] =
    new(result, destroyDict)
    

discard newDict("a", "b")    


