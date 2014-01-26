# We need to open the gensym'ed symbol again so that the instantiation
# creates a fresh copy; but this is wrong the very first reason for gensym
# is that scope rules cannot be used! So simply removing 'sfGenSym' does
# not work. Copying the symbol does not work either because we're already
# the owner of the symbol! What we need to do is to copy the symbol
# in the generic instantiation process...

type
  TA = object
    x: int
  TB = object
    x: string

template genImpl() =
  var gensymed: T
  when T is TB:
    gensymed.x = "abc"
  else:
    gensymed.x = 123
  shallowCopy(result, gensymed)

proc gen[T](x: T): T =
  genImpl()

var
  a: TA
  b: TB
let x = gen(a)
let y = gen(b)

echo x.x, " ", y.x
