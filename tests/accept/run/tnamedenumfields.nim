discard """
  file: "tnamedenumfields.nim"
  output: "my value A0my value Bconc1valueCabc3abc"
"""

const
  strValB = "my value B"

type
  TMyEnum = enum
    valueA = (0, "my value A"),
    valueB = strValB & "conc",
    valueC,
    valueD = (3, "abc"),
    valueE = 4

# trick the optimizer with a variable:
var x = valueD
echo valueA, ord(valueA), valueB, ord(valueB), valueC, valueD, ord(valueD), x




