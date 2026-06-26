# Helper for tgenericoffer.nim: a distinct type whose `==` lives in THIS module.
type MultiCodec* = distinct int
proc `==`*(a, b: MultiCodec): bool = int(a) == int(b)
