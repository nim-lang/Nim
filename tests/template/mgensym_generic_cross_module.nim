
template makeDomElement(x: untyped, name: string = nil) =
  const tag {.gensym.} = if name == nil: astToStr(x) else: name

  proc x*(p: int|float) =
    echo tag, p

  proc x*(p: string|cstring) =
    echo tag, p

#proc wrappedUp[T](x: T) =
#  mixin foo, bar
makeDomElement(foo, "foo")
makeDomElement(bar)
