discard """
  cmd: "nim c -d:danger -r $file"
  output: '''
a
b
c
'''
"""

echo "a"
when defined(release):
  echo "b"
echo "c"
