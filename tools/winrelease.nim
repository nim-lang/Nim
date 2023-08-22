## This is a small helper program to build the Win release.
## This used to be part of koch (and it still uses koch as a library)
## but since 'koch.exe' cannot overwrite itself is now its own program.
## The problem is that 'koch.exe' too is part of the zip bundle and
## needs to have the right 32/64 bit version. (Bug #6147)

import "../koch"

winRelease()
