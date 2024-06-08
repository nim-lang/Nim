discard """
  matrix: "--cc:vcc"
  disabled: "linux"
  disabled: "bsd"
  disabled: "osx"
  disabled: "unix"
  disabled: "posix"
"""

type A = tuple
discard ()
discard default(A)
