# bug #1774
proc p(T: typedesc) = discard

p(type((5, 6)))       # Compiles
(type((5, 6))).p      # Doesn't compile (SIGSEGV: Illegal storage access.)
type T = type((5, 6)) # Doesn't compile (SIGSEGV: Illegal storage access.)

