import mtypename

# Instantiated here first, so the test module reuses these instances until a
# recompilation of the test module drops the instance cache.
const
  intName* = typeName(int)
  stringName* = typeName(string)
  floatName* = typeName(float)
  boolName* = typeName(bool)
  charName* = typeName(char)
