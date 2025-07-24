discard """
    action: run
"""

import .. / modules / [mexporta as a1, definitions as foo1]
import .. / modules / definitions as foo2
import ./[mexporta as a2, definitions as foo3]
import std / times as bar
from times as bar2 import nil
import times as bar3 except convert
import definitions as baz

discard foo1.v
discard foo2.v
discard foo3.v
discard bar.now()
discard bar2.now()
discard bar3.now()
discard baz.v
discard a1.xyz
discard a2.xyz
