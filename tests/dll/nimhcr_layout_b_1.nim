type S* = object
  b*: float
  a*: int
var st* = S(b: 2.0, a: 1)
proc show*(): string = $st.a
