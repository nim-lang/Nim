block:
  let txt = "Hello World"

  template `[]`[T](p: ptr T, span: Slice[int]): untyped =
    toOpenArray(cast[ptr array[0, T]](p)[], span.a, span.b)

  doAssert $cast[ptr uint8](txt[0].unsafeAddr)[0 ..< txt.len] == 
                "[72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100]"


block:
  let txt = "Hello World"

  template `[]`[T](p: ptr T, span: Slice[int]): untyped =
    toOpenArray(cast[ptr array[0, T]](p)[], span.a, span.b)

  doAssert $cast[ptr uint8](txt[0].unsafeAddr)[0 ..< txt.len] == 
                "[72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100]"
