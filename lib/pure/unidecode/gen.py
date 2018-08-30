#! usr/bin/env python
# -*- coding: utf-8 -*-

# Generates the unidecode.dat module
# (c) 2010 Andreas Rumpf

from unidecode import unidecode
import warnings

warnings.simplefilter("ignore")

def main2():
  data = []
  for x in range(128, 0xffff + 1):
    u = eval("u'\\u%04x'" % x)

    val = unidecode(u)
    data.append(val)

  f = open("unidecode.dat", "w+")
  for d in data:
    f.write("%s\n" % d)
  f.close()


main2()
