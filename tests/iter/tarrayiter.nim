block:
  iterator `[]`(a: int, r: int): int = 
    for q in 0 .. r:
      yield a
    
  for val in 10[2]: discard
  
  type Custom = distinct string

  iterator `[]`(a: Custom, r: int): char = 
    for q in 0 .. r:
      yield a.string[q]
      
  for val in Custom("test")[2]: discard