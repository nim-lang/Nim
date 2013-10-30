#! usr/bin/env python
# -*- coding: utf-8 -*-

# Generates the unidecode.dat module
# (c) 2010 Andreas Rumpf

from unidecode import unidecode

def main2():
  data = []
  for x in xrange(128, 0xffff + 1):
    u = eval("u'\u%04x'" % x)

    val = unidecode(u)
    data.append(val)


  f = open("unidecode.dat", "wb+")
  for d in data:
    f.write("%s\n" % d)
  f.close()


main2()


