discard """
  ccodecheck: "\\i@'NI* NIM_NOALIAS field;' @'NIM_CHAR* NIM_NOALIAS x,' @'void* NIM_NOALIAS q'"
"""

type
  BigNum = object
    field {.noalias.}: ptr UncheckedArray[int]

proc p(x {.noalias.}: openArray[char]) =
  var q {.noalias.}: pointer = unsafeAddr(x[0])

var bn: BigNum
p "abc"
