import mexport_a {.cyclic.}, mexport_d {.cyclic.}

proc fb*(x: typeof(fa())): int = fa() + x
