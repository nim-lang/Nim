# Test for overloading

type
  TNone {.export: "_NONE".} = record

proc
  TNone(a, b: int) = nil #ERROR_MSG attempt to redefine 'TNone'
