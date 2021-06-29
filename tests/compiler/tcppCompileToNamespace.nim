discard """
cmd: "nim cpp --cppCompileToNamespace:foo $options -r $file"
"""

# Theoretically nim could just ignore the flag cppCompileToNamespace
# and this test would pass.  Setting ``ccodeCheck`` for a c++ target
# doesn't work.

import os

echo "a" / "b"
