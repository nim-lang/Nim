#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

#  included from sem.nim

# Second semantic checking pass over the AST. Necessary because the old
# way had some inherent problems. Performs:
# 
# * procvar checks
# * effect tracking
# * closure analysis
# * checks for invalid usages of compiletime magics
# * checks for invalid usages of PNimNode
# * later: will do an escape analysis for closures at least


