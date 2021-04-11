{.warning[UnusedImport]: off.} # xxx bug: this shouldn't be needed since we have `export m3`
import ./m3 {.all.}
export m3
# export m3 {.all.} # xxx this could be supported in future
export m3h3
# export m3.m3h4
export m3h4
