discard """
  ccodecheck: "\\i@'NIM_CHAR* NIM_NOALIAS x,' @'void* NIM_NOALIAS q'"
"""

proc p(x {.noalias.}: openArray[char]) =
  var q {.noalias.}: pointer = unsafeAddr(x[0])

p "abc"
