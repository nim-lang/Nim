discard """
  errormsg: "missing closing '}' for Unicode escape sequence"
  line: 6
"""
# the unterminated escape must be the very last thing in the file
let x = "\u{1F6