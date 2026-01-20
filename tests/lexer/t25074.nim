discard """
  matrix: "--warningaserror:longliterals"
  errormsg: "number has 64 digits but type only supports 16 digits: '0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff' [LongLiterals]"
"""

echo $sizeof 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff