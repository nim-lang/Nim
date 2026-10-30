type S* = object
  a*: int
var st* = S(a: 3)
proc show*(): string = "v2 " & $st.a
