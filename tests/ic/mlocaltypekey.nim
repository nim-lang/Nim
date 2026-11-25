proc fa*(n: int): int =
  type Level = object
    g: int
    s: string
  var open: seq[Level]
  for i in 0..<n: open.add Level(g: i, s: $i)
  for x in open: result += x.g + x.s.len
