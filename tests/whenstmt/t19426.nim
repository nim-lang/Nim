type
  MyInt = object
    bitWidth: int

template toRealType*(t: MyInt): typedesc =
  when t.bitWidth == 32: int32
  elif t.bitWidth == 64: int64
  else: {.error.}

proc doFail(T: typedesc): T = default(T)

proc test =
  const myInt = MyInt(bitWidth:32)
  discard doFail(toRealType(myInt))

test()