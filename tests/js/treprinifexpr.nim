type
  Enum = enum A

let
  enumVal = A
  tmp = if true: $enumVal else: $enumVal

let
  intVal = 12
  tmp2 = if true: repr(intVal) else: $enumVal

let
  strVal = "123"
  tmp3 = if true: repr(strVal) else: $strVal

let
  floatVal = 12.4
  tmp4 = if true: repr(floatVal) else: $floatVal