discard """
  file: "texcsub.nim"
  output: "caught!"
"""
# Test inheritance for exception matching:

try:
  raise newException(EOS, "dummy message")
except E_Base:
  echo "caught!"
except:
  echo "wtf!?"

#OUT caught!



