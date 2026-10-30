type S* = object
  b*: string
  a*: int
var st* = S(b: "x", a: 2)
proc show*(): string = "v1 " & $st.a
