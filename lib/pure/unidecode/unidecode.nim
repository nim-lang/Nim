#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module is based on Python's Unidecode module by Tomaz Solc, 
## which in turn is based on the ``Text::Unidecode`` Perl module by 
## Sean M. Burke 
## (http://search.cpan.org/~sburke/Text-Unidecode-0.04/lib/Text/Unidecode.pm).
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
## This module needs the data file "unidecode.dat" to work, so it has to be
## shipped with the application! 

import unicode

proc loadTranslationTable(filename: string): seq[string] =  
  newSeq(result, 0xffff)
  var i = 0
  for line in lines(filename):
    result[i] = line
    inc(i)

var 
  translationTable: seq[string]
  
var
  datafile* = "unidecode.dat"   ## location can be overwritten for deployment

proc unidecode*(s: string): string = 
  ## Finds the sequence of ASCII characters that is the closest approximation
  ## to the UTF-8 string `s`.
  ##
  ## Example: 
  ## 
  ## ..code-block:: nimrod
  ##   unidecode("\x53\x17\x4E\xB0")
  ##
  ## Results in: "Bei Jing"
  ##
  result = ""
  for r in runes(s): 
    var c = int(r)
    if c <=% 127: add(result, chr(c))
    elif c <=% 0xffff: 
      if isNil(translationTable):
        translationTable = loadTranslationTable(datafile)
      add(result, translationTable[c-128])

when isMainModule: 
  echo unidecode("Äußerst")

