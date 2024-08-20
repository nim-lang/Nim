import ./mqualifiedamb2
discard default(K(0))       # works
discard default(mqualifiedamb2.B(0))     # works
discard default(mqualifiedamb2.K(0))     # doesn't work
