#
#
#            Nim's Runtime Library
#        (c) Copyright 2022 Emery Hemingway
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## See `Genode Foundations - Entrypoint <https://genode.org/documentation/genode-foundations/21.05/functional_specification/Entrypoint.html>`
## for a description of Entrypoints.

type
  EntrypointObj {.
    importcpp: "Genode::Entrypoint",
    header: "<base/entrypoint.h>",
    pure.} = object
  Entrypoint* = ptr EntrypointObj
    ## Opaque Entrypoint object.

proc ep*(env: GenodeEnv): Entrypoint {.importcpp: "(&#->ep())".}
  ## Access the entrypoint associated with `env`.
