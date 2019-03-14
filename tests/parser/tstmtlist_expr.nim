proc xx(a: int): int = 
  let y = 0
  return
    var x = 0
    x + y

proc b(x: int): int = 
  raise 
    var e: ref Exception
    new(e)
    e.msg = "My Exception msg"
    e

proc c(x: int): int = 
  if 
    ## "a comment, this block mimics the template expansion"
    let y = x + 2
    y > 0:
      return y
  elif    
    ## "a comment, this block mimics the template expansion"
    let y = x + 2
    y > 0:
      return y
  

proc d(x: int): int = 
  case 
    ## "a comment, this block mimics the template expansion"
    let y = x + 2
    y > 0:
  
  of true: result = 2 # comment
  of false:
    let z = x - 2 
    result = z
  elif    
    ## "a comment, this block mimics the template expansion"
    let y = x + 2
    y > 0:
      return y

##issue 4035
echo(5 +
5)