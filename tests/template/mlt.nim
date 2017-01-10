
type Point* = ref object of RootObj
proc `>`*(p1, p2: Point): bool = false
