discard """
  disabled: i386
  output: "forced to truncate exit code 4294967296 to 0"
"""
# bug #20694
quit(0x100000000.int)