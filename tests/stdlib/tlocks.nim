discard """
  output: '''3'''
  cmd: "nim $target --threads:on $options $file"
"""

#bug #6049
import uselocks

var m = createMyType[int]()
echo $m.use()
