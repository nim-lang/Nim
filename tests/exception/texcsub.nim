discard """
  output: "caught!"
"""
# Test inheritance for exception matching:

try:
  raise newException(OSError, "dummy message")
except Exception:
  echo "caught!"
except:
  echo "wtf!?"

#OUT caught!
