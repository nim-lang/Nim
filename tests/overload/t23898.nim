import ./m23898_2
discard default(B(0))       # compiles
discard default(m23898_2.B(0))     # compiles
discard default(K(0))       # compiles
template r() =
  discard default(B(0))     # compiles
  discard default(m23898_2.B(0))   # compiles
  discard default(K(0))     # does not compile
