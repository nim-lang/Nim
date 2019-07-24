
import hotcodereloading

import nimhcr_1 # new import!

# global scope for this module was executed when loading the program
# with a previous version which didn't contain this print statement
echo "   0: I SHOULDN'T BE PRINTED!"

var g_0 = 0 # changed value but won't take effect

proc getInt*(): int = return g_0 + g_1 + f_1()

beforeCodeReload:
  echo "   0: before - improved!" # changed handlers!
afterCodeReload:
  echo "   0: after - improved!"
  g_0 = 100 # we cannot change it in its initialization but we can in the 'after' handler!
