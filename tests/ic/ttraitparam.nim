discard """
output: '''ok'''
"""

# Regression test: a `typed` macro in an imported module splices param symbols
# out of an imported proc type into a freshly semchecked proc type. Under
# `nim ic` those param symbols are loaded `Sealed` from the NIF cache; reusing
# them in `newSymG`/`semProcTypeNode` used to fail `ast.nim` `s.state != Sealed`.

import mtraitparam

makeVTable(ChunkTrait)

echo "ok"
