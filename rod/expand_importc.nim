#
#
#           The Nimrod Compiler
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Simple tool to expand ``importc`` pragmas. Used for the clean up process of
## the diverse wrappers.

import 
  os, ropes, idents, ast, pnimsyn, rnimsyn
  
  times, commands, scanner, condsyms, options, msgs, nversion, nimconf, ropes, 
  extccomp, strutils, os, platform, main, parseopt

if paramcount() == 0:
  echo ""



