try:
  raise newException(EInvalidValue, "")
except EOverflow:
  echo("Error caught")
  

