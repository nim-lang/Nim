import mexport_b {.cyclic.}, mexport_c {.cyclic.}, mexport_d {.cyclic.}
export mexport_b
export fc, C
export mexport_d except hidden
# the exports do not end the leading declarations: `fa` is still declared
# before `mexport_b` declares its routines
proc fa*(): int = 1
