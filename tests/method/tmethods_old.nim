discard """
  matrix: "--mm:arc -u:nimPreviewVtables"
  output: '''
do nothing
'''
"""

# tmethods1
method somethin(obj: RootObj) {.base.} =
  echo "do nothing"
var o: RootObj
o.somethin()
