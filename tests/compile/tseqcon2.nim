import os

proc rec_dir(dir: string): seq[string] =
  result = @[]
  for kind, path in walk_dir(dir):
    if kind == pcDir:
      add(result, rec_dir(path))
    else:
      add(result, path)
