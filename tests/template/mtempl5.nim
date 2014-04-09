
var 
  gx = 88
  gy = 44
  
template templ*(): int =
  bind gx, gy
  gx + gy
  

