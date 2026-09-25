discard """
  description: '''IC: discover macro-generated import chains past twenty rounds'''
"""

#? metamorphic

# Each module imports the next through a macro, so the static dependency scan
# discovers only one new link after each semantic pass. Keep the chain longer
# than the old fixed 20-round limit to exercise the discovery fixpoint.

#!FILE deepimportgen.nim
import std/macros

macro importNext*(path: untyped): untyped =
  parseStmt("import " & path.strVal)

#!FILE deepimport00.nim
import deepimportgen
importNext("deepimport01")

#!FILE deepimport01.nim
import deepimportgen
importNext("deepimport02")

#!FILE deepimport02.nim
import deepimportgen
importNext("deepimport03")

#!FILE deepimport03.nim
import deepimportgen
importNext("deepimport04")

#!FILE deepimport04.nim
import deepimportgen
importNext("deepimport05")

#!FILE deepimport05.nim
import deepimportgen
importNext("deepimport06")

#!FILE deepimport06.nim
import deepimportgen
importNext("deepimport07")

#!FILE deepimport07.nim
import deepimportgen
importNext("deepimport08")

#!FILE deepimport08.nim
import deepimportgen
importNext("deepimport09")

#!FILE deepimport09.nim
import deepimportgen
importNext("deepimport10")

#!FILE deepimport10.nim
import deepimportgen
importNext("deepimport11")

#!FILE deepimport11.nim
import deepimportgen
importNext("deepimport12")

#!FILE deepimport12.nim
import deepimportgen
importNext("deepimport13")

#!FILE deepimport13.nim
import deepimportgen
importNext("deepimport14")

#!FILE deepimport14.nim
import deepimportgen
importNext("deepimport15")

#!FILE deepimport15.nim
import deepimportgen
importNext("deepimport16")

#!FILE deepimport16.nim
import deepimportgen
importNext("deepimport17")

#!FILE deepimport17.nim
import deepimportgen
importNext("deepimport18")

#!FILE deepimport18.nim
import deepimportgen
importNext("deepimport19")

#!FILE deepimport19.nim
import deepimportgen
importNext("deepimport20")

#!FILE deepimport20.nim
import deepimportgen
importNext("deepimport21")

#!FILE deepimport21.nim
import deepimportgen
importNext("deepimport22")

#!FILE deepimport22.nim
discard

#!FILE main.nim
import deepimport00
echo "imports discovered"
#!STEP expect: imports discovered
