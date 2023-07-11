type
  Foo = object of RootObj
  Bar = object of Foo

# previously true
block:
  proc p(x:Foo):bool= false
  proc p[T](x:T):bool= true
  doAssert p(Bar()) == false

block:
  proc p(x:Foo):bool= false
  proc p(x:object):bool= true
  doAssert p(Bar()) == false

block:
  proc p(x:Foo):bool= false
  proc p(x:RootObj | object):bool= true
  doAssert p(Bar()) == false

block:
  # The generic equivallent of this is corrected in PR #22143
  proc p(x:Foo):bool= false
  proc p(x:object | Bar):bool= true
  doAssert p(Bar()) == false
