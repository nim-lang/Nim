# this tests the new overflow literals

var
  i: int
i = int(0xffffffff)
when defined(cpu64):
  if i == 4294967295:
    write(stdout, "works!\n")
  else:
    write(stdout, "broken!\n")
else:
  if i == -1:
    write(stdout, "works!\n")
  else:
    write(stdout, "broken!\n")

#OUT works!
