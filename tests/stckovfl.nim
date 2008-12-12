# To test stack overflow message

proc over(a: int): int = 
  if a == high(int): return
  result = over(a+1)+5
  
Echo($over(0))

