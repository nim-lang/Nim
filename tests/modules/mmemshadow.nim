type CPUMemory* = object
  data*: array[4, uint16]

proc read16*(mem: CPUMemory; adr: uint16): uint16 = mem.data[int(adr and 3)]
