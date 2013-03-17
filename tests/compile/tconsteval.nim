discard """
"""

import strutils

const
  HelpText = """
+-----------------------------------------------------------------+
|         Maintenance program for Nimrod                          |
|             Version $1|
|             (c) 2012 Andreas Rumpf                              |
+-----------------------------------------------------------------+
Compiled at: $2, $3

Usage:
  koch [options] command [options for command]
Options:
  --force, -f, -B, -b      forces rebuild
  --help, -h               shows this help and quits
Possible Commands:
  boot [options]           bootstraps with given command line options
  clean                    cleans Nimrod project; removes generated files
  web                      generates the website
  csource [options]        builds the C sources for installation
  zip                      builds the installation ZIP package
  inno                     builds the Inno Setup installer
""" % [NimrodVersion & repeatChar(44-len(NimrodVersion)), 
       CompileDate, CompileTime]

echo helpText

