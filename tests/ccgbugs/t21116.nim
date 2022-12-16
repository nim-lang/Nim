discard """
  target: "c cpp"
  disabled: windows
"""
# bug #21116
import posix

proc p(glob: string) =
  discard posix.glob(glob, 0, nil, nil)

p "*"
