discard """
  cmd: "nim check $options --defusages:$file,12,7 $file"
  nimout: '''def tnav1_temp.nim(11, 10)
usage tnav1_temp.nim(12, 8)
  '''
"""


import std / [times]

proc foo(x: int) =
  echo x

foo(3)
echo "yes", 1 != 3

#!EDIT!#
discard """
  cmd: "nim check $options --defusages:$file,15,2 $file"
  nimout: '''def tnav1_temp.nim(12, 6)
usage tnav1_temp.nim(15, 1)
  '''
"""


import std / [times]

proc foo(x: int) =
  echo x

foo(3)
echo "yes", 1 != 3

