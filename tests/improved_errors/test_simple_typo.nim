# Simple typo test - identifier not found

proc test() =
  let length = 10
  # Typo: "lenght" instead of "length"
  echo lenght  # This should trigger the improved error with suggestion
