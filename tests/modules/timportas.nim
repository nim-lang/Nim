discard """
    action: run
"""

import .. / modules / [definitions as foo]
import std / times as bar
import definitions as baz

discard foo.v
discard bar.now
discard baz.v