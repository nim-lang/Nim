type S* = object
  a*: int
var st* = S(a: 1)
proc show*(): string = "v0 " & $st.a
