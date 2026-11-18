proc count*(s: seq[int]): int =
  for x in s: result += x
