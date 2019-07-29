import std/sugar

template fun6(): untyped = 42

{.push experimental: "aliasSym".}
alias: fun6a*=fun6 # alias with export
