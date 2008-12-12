import tre

fz = tre.Fuzzyness(maxcost = 3)

print fz

pt = tre.compile("(foo)(bar)", tre.EXTENDED)

m = pt.match("zoobag", fz)

if m:
    print m.groups()
    print m[2]
