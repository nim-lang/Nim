## .. importdoc:: ../../util.nim, ../main.nim, ../doc/manual.md
##
## Ref. [object A] from [module nimdoc/extlinks/project/main].
##
## Ref. [utilfunction(x: int)].
##
## Ref. [Second section &] from [Nothing User Manual].

proc `</a>`*(x, y: int): bool =
  ## Attempt to break HTML formatting.
  result = x < y

type submoduleInt* = distinct int
