#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Nimrod Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module defines compile-time reflection procs for
## working with types

proc name*(t: typedesc): string {.magic: "TypeTrait".}
  ## Returns the name of the given type

