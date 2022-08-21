discard """
  cmd: "nim c $file"
  action: "compile"
"""

proc taggy() {.tags: RootEffect.} = discard

proc m {.raises: [], tags: [].} =
  {.cast(noSideEffect).}:
    echo "hi"

  {.cast(raises: []).}:
    raise newException(ValueError, "bah")

  {.cast(tags: []).}:
    taggy()

m()
