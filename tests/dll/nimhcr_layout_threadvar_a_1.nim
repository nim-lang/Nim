type S* = object
  a*: int
  b*: int
  c*: string
var st* {.threadvar.}: S
proc setup*() = st = S(a: 1, b: 2, c: "x")
proc show*(): string = $st.a
