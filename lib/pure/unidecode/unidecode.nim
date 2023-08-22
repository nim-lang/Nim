#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module is based on Python's [Unidecode](https://pypi.org/project/Unidecode/)
## module by Tomaz Solc, which in turn is based on the
## [Text::Unidecode](https://metacpan.org/pod/Text::Unidecode)
## Perl module by Sean M. Burke.
##
## It provides a `unidecode proc <#unidecode,string>`_ that does
## Unicode to ASCII transliterations: It finds the sequence of ASCII characters
## that is the closest approximation to the Unicode string.
##
## For example, the closest to string "Äußerst" in ASCII is "Ausserst". Some
## information is lost in this transformation, of course, since several Unicode
## strings can be transformed to the same ASCII representation. So this is a
## strictly one-way transformation. However, a human reader will probably
## still be able to guess from the context, what the original string was.
##
## This module needs the data file `unidecode.dat` to work: This file is
## embedded as a resource into your application by default. You can also
## define the symbol `--define:noUnidecodeTable` during compile time and
## use the `loadUnidecodeTable proc <#loadUnidecodeTable>`_ to initialize
## this module.

import std/unicode

when not defined(noUnidecodeTable):
  import std/strutils

  const translationTable = splitLines(slurp"unidecode/unidecode.dat")
else:
  # shared is fine for threading:
  var translationTable: seq[string]

proc loadUnidecodeTable*(datafile = "unidecode.dat") =
  ## Loads the datafile that `unidecode <#unidecode,string>`_ needs to work.
  ## This is only required if the module was compiled with the
  ## `--define:noUnidecodeTable` switch. This needs to be called by the
  ## main thread before any thread can make a call to `unidecode`.
  when defined(noUnidecodeTable):
    newSeq(translationTable, 0xffff)
    var i = 0
    for line in lines(datafile):
      translationTable[i] = line
      inc(i)

proc unidecode*(s: string): string =
  ## Finds the sequence of ASCII characters that is the closest approximation
  ## to the UTF-8 string `s`.
  runnableExamples:
    doAssert unidecode("北京") == "Bei Jing "
    doAssert unidecode("Äußerst") == "Ausserst"

  result = ""
  for r in runes(s):
    var c = int(r)
    if c <=% 127: add(result, chr(c))
    elif c <% translationTable.len: add(result, translationTable[c - 128])
