discard """
  errormsg: "index type 'int' for array is too large"
  line: 9
"""

# bug #11737: no codegen crash for an array whose index type is too large
proc g[N](): array[N, byte] = discard
# a value for the type parameter `N` makes it `int`:
discard g[4]()
