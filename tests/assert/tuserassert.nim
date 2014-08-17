discard """
  output: "x == 45ugh"
"""

template myAssert(cond: expr) = 
  when 3 <= 3:
    let c = cond.astToStr
    if not cond:
      echo c, "ugh"
  
var x = 454
myAssert(x == 45)

