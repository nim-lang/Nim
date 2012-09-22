discard """
  file: "tenumhole.nim"
  output: "my value A1my value Bconc2valueCabc4abc"
"""

const
  strValB = "my value B"

type
  TMyEnum = enum
    valueA = (1, "my value A"),
    valueB = strValB & "conc",
    valueC,
    valueD = (4, "abc")
 
# test the new "proc body can be an expr" feature:
proc getValue: TMyEnum = valueD
 
# trick the optimizer with a variable:
var x = getValue()
echo valueA, ord(valueA), valueB, ord(valueB), valueC, valueD, ord(valueD), x




