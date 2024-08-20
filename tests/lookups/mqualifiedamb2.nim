import ./mqualifiedamb1
export mqualifiedamb1
template K*(kind: static int): auto = typedesc[mqualifiedamb1.K]
template B*(kind: static int): auto = typedesc[mqualifiedamb1.K]
