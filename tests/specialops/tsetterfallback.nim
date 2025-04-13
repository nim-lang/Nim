# https://forum.nim-lang.org/t/12785

proc x(pt: var array[2, float]): var float = pt[0]

var pt = [0.0, 0.0]
pt.x += 1.0 # <-- fine
x(pt) = 1.0 # <-- fine
pt.x = 1.0 # <-- does not compile
