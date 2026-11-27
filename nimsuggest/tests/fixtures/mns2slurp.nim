const slurped = staticRead("ns2slurped.txt")
when slurped == "one\n":
  proc text*(): string = "one"
else:
  proc text*(): string = "two"
