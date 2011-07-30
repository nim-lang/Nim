discard """
  output: "true true false yes"
"""

proc IsVoid[T](): string = 
  when T is void:
    result = "yes"
  else:
    result = "no"

const x = int is int
echo x, " ", float is float, " ", float is string, " ", IsVoid[void]()

