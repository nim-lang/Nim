discard """
  cmd: "nim check $options --defusages:$file,12,7 $file"
  nimout: '''def tincludefile_temp.nim(11, 10)
usage tincludefile_temp.nim(12, 8)
  '''
"""




proc foo(x: int) =
  echo x

foo(3)
echo "yes", 1 != 3

#!EDIT!#
discard """
  cmd: "nim check $options --defusages:$file/../minclude.nim,2,2 $file"
  nimout: '''def tincludefile_temp.nim(10, 6)
usage minclude.nim(2, 1)
  '''
"""


proc foo(x: int) =
  echo x

include minclude
