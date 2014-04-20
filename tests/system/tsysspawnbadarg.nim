discard """
  line: 7
  errormsg: "'spawn' takes a call expression of type void"
  cmd: "nimrod $target --threads:on $options $file"
"""

spawn(1)
