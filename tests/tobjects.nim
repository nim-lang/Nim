import
  io

type
  TBase = object
    x, y: int

  TSubclass = object of TBase
    c: int
    case c
    of 0, 1, 2, 3:
      a, b: int
    of 4:
      d, e, f: char
    n: bool

var
  global: int

var
  s: string
  r: float = 0.0
  i: int = 500 + 400

case i
of 500..999: write(stdout, "ha!\n")
of 1000..3000, 12: write(stdout, "ganz schˆn groﬂ\n")
of 1, 2, 3: write(stdout, "1 2 oder 3\n")
else: write(stdout, "sollte nicht passieren\n")

case r
of 0.0, 0.125..0.4444: write(stdout, "kleiner als 0.5\n")
else: write(stdout, "weiﬂ nicht\n")

case readLine(stdin)
of "Rumpf": write(stdout, "Hallo Meister!\n")
of "Andreas": write(stdout, "Hallo Meister!\n")
else: write(stdout, "Nicht mein Meister!\n")

global = global + 1
write(stdout, "Hallo wie heiﬂt du? \n")
s = readLine(stdin)
i = 0
while i < length(s):
  if s[i] == 'c': write(stdout, "'c' in deinem Namen gefunden\n")
  i = i + 1

write(stdout, "Du heiﬂt " & s)
