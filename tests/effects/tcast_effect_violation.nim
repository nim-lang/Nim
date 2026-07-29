discard """
  errormsg: "cast(raises: ValueError) can raise an unlisted exception: ValueError"
  line: 7
"""

proc fff() {.raises: [].} =
  {.cast(raises: ValueError).}:
    discard