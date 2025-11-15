# Test file to demonstrate improved error messages

proc example() =
  # Test 1: Undeclared identifier
  echo undeclaredVar

  # Test 2: Type mismatch
  var x: int = "hello"

  # Test 3: Wrong number of arguments
  let y = max(1, 2, 3, 4)

# Test 4: Using undefined proc
unknown_proc()
