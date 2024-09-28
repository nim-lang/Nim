block: # issue #22793
  const x = @["a", "b"]

  proc myProc(x: seq[string]): seq[string] =
    result = x
  doAssert x.myProc() == @["a", "b"]
  doAssert x.myProc() == x

  proc myProc2(x: seq[string] = @[]): seq[string] = # Compiler correctly infers that `@[]` is `seq[string]`
    result = x
  doAssert x.myProc2() == @["a", "b"]
  doAssert x.myProc2() == x
    
  proc myProc3(x: static seq[string]): seq[string] =
    result = x
  doAssert x.myProc3() == @["a", "b"]
  doAssert x.myProc3() == x

  proc myProc4(x: static seq[string] = @[]): seq[string] = # This proc causes a compiler error. Compiler does not infer that `@[]` is `static seq[string]`
    result = x
  doAssert x.myProc4() == @["a", "b"]
  doAssert x.myProc4() == x
