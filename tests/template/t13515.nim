discard """
  action: compile
"""

template test: bool = true

# compiles:
if not test:
  echo "wtf"

# does not compile:
template x =
  if not test:
    echo "wtf"

x
