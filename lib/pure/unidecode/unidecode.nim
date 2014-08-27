#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module is based on Python's Unidecode module by Tomaz Solc, 
## which in turn is based on the ``Text::Unidecode`` Perl module by 
## Sean M. Burke 
## (http://search.cpan.org/~sburke/Text-Unidecode-0.04/lib/Text/Unidecode.pm ).
##
## It provides a single proc that does Unicode to ASCII transliterations:
## It finds the sequence of ASCII characters that is the closest approximation
## to the Unicode string.
##
## For example, the closest to string "Äußerst" in ASCII is "Ausserst". Some 
## information is lost in this transformation, of course, since several Unicode 
## strings can be transformed in the same ASCII representation. So this is a
## strictly one-way transformation. However a human reader will probably 
## still be able to guess what original string was meant from the context.
##
## This module needs the data file "unidecode.dat" to work: You can either
## ship this file with your application and initialize this module with the
## `loadUnidecodeTable` proc or you can define the ``embedUnidecodeTable``
## symbol to embed the file as a resource into your application.

import unicode

when defined(embedUnidecodeTable):
  import strutils
  
  const translationTable = splitLines(slurp"unidecode/unidecode.dat")
else:
  # shared is fine for threading:
  var translationTable: seq[string]

proc loadUnidecodeTable*(datafile = "unidecode.dat") =
  ## loads the datafile that `unidecode` to work. Unless this module is
  ## compiled with the ``embedUnidecodeTable`` symbol defined, this needs
  ## to be called by the main thread before any thread can make a call
  ## to `unidecode`.
  when not defined(embedUnidecodeTable):
    newSeq(translationTable, 0xffff)
    var i = 0
    for line in lines(datafile):
      translationTable[i] = line.string
      inc(i)

proc unidecode*(s: string): string = 
  ## Finds the sequence of ASCII characters that is the closest approximation
  ## to the UTF-8 string `s`.
  ##
  ## Example: 
  ## 
  ## ..code-block:: nim
  ##
  ##   unidecode("\x53\x17\x4E\xB0")
  ##
  ## Results in: "Bei Jing"
  ##
  assert(not isNil(translationTable))
  result = ""
  for r in runes(s): 
    var c = int(r)
    if c <=% 127: add(result, chr(c))
    elif c <% translationTable.len: add(result, translationTable[c-128])

when isMainModule:
  loadUnidecodeTable("lib/pure/unidecode/unidecode.dat")
  echo unidecode("Äußerst")

