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
  E*[T] = object
    he1: int
  FSub[T1, T2] = object
    h3: T1
    h4: T2
  F*[T1, T2] = ref FSub[T1, T2]

proc initB*(): B = B()
