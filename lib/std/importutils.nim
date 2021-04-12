##[
Experimental API, subject to change.
]##

# proc privateAccess*(sym: untyped) {.magic: PrivateAccess.}
# proc privateAccess*(t: typedesc) {.magic: PrivateAccess.}
proc privateAccess*(t: typedesc) {.magic: "PrivateAccess".}
