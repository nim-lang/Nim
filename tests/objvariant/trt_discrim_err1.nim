discard """
  errormsg: "branch initialization with a runtime discriminator is not supported inside of an `elif` branch."
  line: 16
"""
type
  Color = enum Red, Green, Blue
  ColorObj = object
    case colorKind: Color
    of Red: red: string
    of Green: green: string
    of Blue: blue: string

let colorKind = Blue
case colorKind
of Red: echo ColorObj(colorKind: colorKind, red: "red")
elif colorKind == Green: echo ColorObj(colorKind: colorKind, green: "green")
else: echo ColorObj(colorKind: colorKind, blue: "blue")
