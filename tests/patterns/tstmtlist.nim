discard """
  output: '''0
|12|34
'''
"""

template optWrite{
  write(stdout, x)
  write(stdout, y)
}(x, y: string) =
  write(stdout, "|", x, y, "|")

if true:
  echo "0"
  write stdout, "1"
  write stdout, "2"
  write stdout, "3"
  echo "4"
