discard """
  file: "tendian.nim"
"""
# test the new endian magic

writeLine(stdout, repr(system.cpuEndian))
