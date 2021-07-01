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
  G*[T] = ref E[T]
  H3*[T] = object
    h5: T
  H2*[T] = H3[T]
  H1*[T] = ref H2[T]
  H*[T] = H1[T]

type BAalias* = typeof(B.default)
  # typeof is not a transparent abstraction, creates a `tyAlias`

proc initB*(): B = B()
