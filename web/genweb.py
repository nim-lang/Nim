#!/usr/bin/env python

# Generates the beautiful webpage.
# (c) 2007 Andreas Rumpf

TABS = [ # Our tabs: (Menu entry, filename)
  ("home", "index"),
  ("documentation", "documentation"),
  ("download", "download"),
  ("Q&A", "question"), 
  ("links", "links")
]

TEMPLATE_FILE = "sunset.tmpl"

import sys, string, re, glob, os
from Cheetah.Template import Template
from time import gmtime, strftime

def Exec(cmd):
  print cmd
  return os.system(cmd) == 0

def Remove(f):
  try:
    os.remove(f)
  except OSError:
    Warn("could not remove: %s" % f)

def main():
  CMD = "rst2html.py --template=docutils.tmpl %s.txt %s.temp "
  if not Exec(CMD % ("news","news")): return
  newsText = file("news.temp").read()
  for t in TABS:
    if not Exec(CMD % (t[1],t[1]) ): return

    tmpl = Template(file=TEMPLATE_FILE)
    tmpl.content = file(t[1] + ".temp").read()
    tmpl.news = newsText
    tmpl.tab = t[1]
    tmpl.tabs = TABS
    tmpl.lastupdate = strftime("%Y-%m-%d %X", gmtime())
    f = file(t[1] + ".html", "w+")
    f.write(str(tmpl))
    f.close()
  # remove temporaries:
  Remove("news.temp")
  for t in TABS:
    Remove(t[1] + ".temp")

if __name__ == "__main__":
  main()
