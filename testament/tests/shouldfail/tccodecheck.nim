discard """
  ccodecheck: "baz"
"""

proc foo(): void {.exportc: "bar".}=
  echo "Hello World"

foo()
