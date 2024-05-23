block: # issue #22216
  type
    Result[T, E] = object
      case oVal: bool
      of false:
        eVal: E
      of true:
        vVal: T

  func raiseResultDefect(m: string) {.noreturn, noinline.} =
    raise (ref Defect)(msg: m)

  template withAssertOk(self: Result, body: untyped): untyped =
    case self.oVal
    of false:
      raiseResultDefect("Trying to access value with err Result")    
    else:
      body

  func value[T, E](self: Result[T, E]): T {.inline.} =    
    withAssertOk(self):  
      self.vVal
      
  const
    x = Result[int, string](oVal: true, vVal: 123)
    z = x.value()
    
  let
    xx = Result[int, string](oVal: true, vVal: 123)
    zz = x.value()
  
  doAssert z == zz
