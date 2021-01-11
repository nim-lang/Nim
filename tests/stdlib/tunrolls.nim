discard """
  targets: "c cpp js"
  action: compile
"""

import std/unrolls


for i in unrollIt([0, 1, 2, 3]):
    echo it


for i in unrollIt([0.0, 1.0, 2.0, 3.0, 4.0, 5.0]):
  echo it


for i in unrollIt([(0, 1, 2), (3, 4, 5)]):
  echo it


for i in unrollIt([('a', true), ('b', false)]):
  echo it
