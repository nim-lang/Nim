##[
Utilities related to import and symbol resolution.

Experimental API, subject to change.
]##

proc privateAccess*(t: typedesc) {.magic: "PrivateAccess".}
  ## Enables access to private fields of `t` in current scope.
