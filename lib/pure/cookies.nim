#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements helper procs for parsing Cookies.

import strtabs

proc parseCookies*(s: string): PStringTable = 
  ## parses cookies into a string table.
  result = newStringTable(modeCaseInsensitive)
  var i = 0
  while true:
    while s[i] == ' ' or s[i] == '\t': inc(i)
    var keystart = i
    while s[i] != '=' and s[i] != '\0': inc(i)
    var keyend = i-1
    if s[i] == '\0': break
    inc(i) # skip '='
    var valstart = i
    while s[i] != ';' and s[i] != '\0': inc(i)
    result[substr(s, keystart, keyend)] = substr(s, valstart, i-1)
    if s[i] == '\0': break
    inc(i) # skip ';'

