discard """
  errormsg: "missing closing '}' for Unicode escape sequence"
  line: 5
"""
let x = "\u{41" & "}"
