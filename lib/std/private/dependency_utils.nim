##[
Experimental, subject to change
]##

proc addDependency*(name: string) {.magic: "AddDependency".} =
  ## Adds a dependency on `name`; currently only `dragonbox` is supported.
  # a pragma would be possible but cause more boilerplate, and also would be less flexible
  # in case we want to also return something about the depenedncy
