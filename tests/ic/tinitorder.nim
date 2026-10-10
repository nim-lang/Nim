discard """
output: '''42 3'''
"""

# Regression test for per-module-backend module-init ORDERING.
#
# NimMain must call each module's init in DEPENDENCY (post-order) order: an
# imported module's init has to run before its importer's. The whole-program
# backend gets this for free (it iterates `modulesClosed`, built in module-finish
# order); the per-module backend reconstructs it in `nifbackend`. The earlier
# code iterated `bl.mods` by POSITION, which runs importers before their
# dependencies (an importer gets a lower file position than the modules it
# imports) — and the system module (which runs `initGC` in its init) was not
# ordered first at all.
#
# Module chain: tinitorder -> minitordera -> minitorderb. `minitorderb`'s init
# sets a global to 42; `minitordera`'s init reads it (and allocates a seq). With
# the buggy order `minitordera` runs first and reads 0 (or, under refc, crashes
# allocating before the GC is up). Correct order prints `42 3`.

import minitordera

echo getASawB(), " ", getACount()
