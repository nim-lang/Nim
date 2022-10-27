
#type Natural = range[0 .. high(int)]
type Negative = range[low(int) .. -1]
proc `^`(a: bool, b: static[Natural]): int = 1
proc `^`(a: bool, b: static[Negative]): int = 2
discard true ^ -3
