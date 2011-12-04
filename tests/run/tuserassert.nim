discard """
  output: "454 == 45ugh"
"""

template myAssert(cond: expr) = 
  when rand(3) < 2:
    let c = cond.astToStr
    {.warning: "code activated: " & c.}
    if not cond:
      echo c, "ugh"
  

myAssert(454 == 45)

