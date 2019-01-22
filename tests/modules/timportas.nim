discard """
    action: run
"""

import .. / modules / [definitions as foo]
import .. / modules / definitions as foo
import std / times as bar
from times as bar2 import nil
import times as bar3 except convert
import definitions as baz

discard foo.v
discard bar.now()
discard bar2.now()
discard bar3.now()
discard baz.v
