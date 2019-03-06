#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## `options` module is deprecated.
##
## For basic operations with `Option[T]` type, use
## `optionals module <optionals.html>`_.
## For more functionality, use `optutils module <optutils.html>`_.

{.deprecated: "import 'optionals' instead".}

import optionals
export optionals

import optutils
export optutils
