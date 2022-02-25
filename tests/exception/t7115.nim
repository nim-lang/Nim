discard """
  targets: "c cpp"
"""

# bug #7115
doAssert(not compiles(
  try: 
    echo 1
  except [KeyError as ex1, ValueError as ex2]:
    echo 2
))
