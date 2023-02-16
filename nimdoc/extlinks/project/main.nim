## my heading
## ==========
##
## .. importdoc:: sub/submodule.nim, ../util.nim, doc/manual.md
##
## .. See also [Second&&&] and particularly [first section] and [Second section &].
## 
## See also [module nimdoc/extlinks/util] or [nimdoc/extlinks/project/sub/submodule module].
##
## Ref. [`</a>` proc].
##
## Ref. [First section] or [Second section &] from [Nothing User Manual].


import ../util, sub/submodule

type A* = object
  x: int

proc mainfunction*(): int =
  # just to suppress "not used" warnings:
  if `</a>`(1, 2):
    result = utilfunction(0)
