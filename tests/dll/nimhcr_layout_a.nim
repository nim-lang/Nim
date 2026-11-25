type S* = object
  a*: int
  b*: int
var st* = S(a: 1, b: 2)
proc show*(): string = $st.a
