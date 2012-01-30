discard """
  output: "454 == 45ugh"
"""

template myAssert(cond: expr) = 
  when rand(3) < 3:
    let c = cond.astToStr
    if not cond:
      echo c, "ugh"
  

myAssert(454 == 45)

