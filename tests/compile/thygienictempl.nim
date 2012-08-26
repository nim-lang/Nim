    
var
  e = "abc"
    
raise newException(EIO, e & "ha!")

template t() = echo(foo)

var foo = 12
t()
