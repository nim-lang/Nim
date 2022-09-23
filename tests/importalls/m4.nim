{.warning[UnusedImport]: off.} # xxx bug: this shouldn't be needed since we have `export m3`
import ./m3 {.all.}
import ./m3 as m3b
export m3b
export m3h3
export m3.m3h4

import ./m2 {.all.} as m2b
export m2b except bar3

