type S* = object
  a*: int
  b*: float
var st* = S(a: 1, b: 2.0)
proc show*(): string = $st.a
