discard """
  cmd: "nim $target -d:release $options $file"
  output: '''
assertion occured!!!!!! false
'''
"""

onFailedAssert(msg):
  echo("assertion occured!!!!!! ", msg)

doAssert(1 == 2)
