discard """
  matrix: "--warningaserror:BareExcept"
"""

{.warning[BareExcept]:on.}:
  discard

try:
  echo "Y"
except:  # warning disabled here
  discard