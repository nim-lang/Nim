discard """
  file: "tinvalidintegerliteral3.nim"
  line: 7
  errormsg: "0O5 is an invalid int literal; For octal literals use the '0o' prefix."
"""

echo 0O5
