type
  A* = object
    a0*: int
    ha1: float
  B = object
    b0*: int
    hb1: float
  C* = ref object
    c0: int
    hc1: float
  D* = ptr object
    d0: int
    hd1: float
  PA* = ref A
  PtA* = ptr A

proc initB*(): B = B()
