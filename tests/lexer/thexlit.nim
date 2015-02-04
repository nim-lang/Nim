discard """
  file: "thexlit.nim"
  output: "equal"
"""

var t=0x950412DE

if t==0x950412DE:
    echo "equal"
else:
    echo "not equal"

