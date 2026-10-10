discard """
  output: '''true
42'''
"""

# A macrocache value that is an untyped routine AST is replayed from the
# imported module's top level; the backend must not treat it as code.

import std/[macros, macrocache], mmacrocacheproc

macro known(name: static string): bool =
  newLit(name in procs)

echo known("hello")
echo hello()
