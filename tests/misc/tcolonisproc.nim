
proc p(a, b: int, c: proc ()) =
  c()

 
p(1, 3): 
  echo 1
  echo 3
    
p(1, 1, proc() =
  echo 1
  echo 2)
