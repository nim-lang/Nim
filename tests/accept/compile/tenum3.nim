# Test enum with explicit size

type
  TEnumHole {.size: sizeof(int).} = enum 
    eA = 0,
    eB = 4,
    eC = 5
    
var
  e: TEnumHole = eB
  
case e
of eA: echo "A"
of eB: echo "B"
of eC: echo "C"

