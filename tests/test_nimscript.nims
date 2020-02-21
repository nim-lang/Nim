# This nimscript is used to test if the following modules can be imported
# http://nim-lang.org/docs/nims.html

import algorithm
import base64
import colors
import hashes
import lists
import math
# import marshal
import options
import os
# import parsecfg
# import parseopt
import parseutils
# import pegs
import deques
import sequtils
import strutils
import tables
import unicode
import uri
import macros

block:
  doAssert "./foo//./bar/".normalizedPath == "foo/bar".unixToNativePath

echo "Nimscript imports are successful."
