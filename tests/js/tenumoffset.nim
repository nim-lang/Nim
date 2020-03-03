discard """
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

proc getValue(i:int): TMyEnum = TMyEnum(i)

# trick the optimizer with a variable:
var x = getValue(4)
echo getValue(1), ord(valueA), getValue(2), ord(valueB), getValue(3), getValue(4), ord(valueD), x
