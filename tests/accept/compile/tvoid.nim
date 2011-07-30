discard """
  output: "he, no return type; a string"
"""

proc ReturnT[T](): T =
  when T is void:
    echo "he, no return type;"
  else:
    result = " a string"

ReturnT[void]()
echo ReturnT[string]()

